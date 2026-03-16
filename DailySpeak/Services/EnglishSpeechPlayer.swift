import AVFoundation
import Combine
import Foundation

struct PlaybackContext: Equatable {
    let id: String
    let text: String
    let sourceLabel: String
}

@MainActor
final class EnglishSpeechPlayer: NSObject, ObservableObject {
    static let shared = EnglishSpeechPlayer()

    @Published private(set) var activePlaybackID: String?
    @Published private(set) var loadingPlaybackID: String?
    @Published private(set) var pausedPlaybackID: String?
    @Published private(set) var playbackContext: PlaybackContext?
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var failedToPlayObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var timeObserver: Any?
    private var cachedAudioURLs: [String: URL] = [:]
    private var cachedAudioDurations: [String: Double] = [:]
    private var requestSequence = 0
    private var activeDownloads: [String: Task<URL?, Never>] = [:]

    private static var cacheDirectory: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("tts-audio", isDirectory: true)
    }

    private override init() {
        super.init()
        let dir = Self.cacheDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        loadDiskCache()
    }

    private func loadDiskCache() {
        let dir = Self.cacheDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "mp3" {
            let id = file.deletingPathExtension().lastPathComponent
            cachedAudioURLs[id] = file
        }
        if !cachedAudioURLs.isEmpty {
            print("ℹ️ [TTS] loaded \(cachedAudioURLs.count) cached audio files from disk")
        }
    }

    static func playbackID(for text: String, category: String = "english") -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(category)-\(AppleSignInNonce.sha256(normalized))"
    }

    func clearAudioCache() {
        cachedAudioURLs.removeAll()
        cachedAudioDurations.removeAll()
        try? FileManager.default.removeItem(at: Self.cacheDirectory)
        try? FileManager.default.createDirectory(at: Self.cacheDirectory, withIntermediateDirectories: true)
    }

    func isAudioCached(id: String) -> Bool {
        if cachedAudioURLs[id] != nil { return true }
        let file = Self.cacheDirectory.appendingPathComponent("\(id).mp3")
        if FileManager.default.fileExists(atPath: file.path) {
            cachedAudioURLs[id] = file
            return true
        }
        return false
    }

    /// Returns the cached audio duration in seconds, or nil if not prepared.
    func cachedDuration(id: String) -> Double? {
        cachedAudioDurations[id]
    }

    /// Fetch audio URL, download MP3 to local file, probe duration, and cache.
    func prepareAudio(id: String, text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if cachedAudioURLs[id] != nil { return true }
        guard let localURL = await downloadToLocal(id: id, text: trimmed) else { return false }
        // Probe duration
        do {
            let asset = AVAsset(url: localURL)
            let cmDuration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(cmDuration)
            if seconds.isFinite && seconds > 0 {
                cachedAudioDurations[id] = seconds
            }
        } catch {
            print("⚠️ [TTS] duration probe failed: \(error.localizedDescription)")
        }
        return true
    }

    /// Batch preload: resolve all URLs in one API call, then download MP3s in parallel.
    /// Returns the number of successfully cached items.
    @discardableResult
    func preloadBatch(_ items: [(id: String, text: String)]) async -> Int {
        // Filter out already-cached items
        let uncached = items.filter { !isAudioCached(id: $0.id) }
        guard !uncached.isEmpty else {
            print("ℹ️ [TTS] preloadBatch: all \(items.count) items already cached")
            return items.count
        }

        print("⬇️ [TTS] preloadBatch: \(uncached.count) uncached / \(items.count) total")

        // Step 1: Batch API call to resolve all audio URLs at once
        let voiceId = VoiceManager.shared.selectedVoiceId
        let urlMap: [String: URL]
        do {
            urlMap = try await DailySpeakAPIService.shared.generateEnglishAudioURLBatch(
                items: uncached,
                voiceId: voiceId
            )
        } catch {
            print("⚠️ [TTS] batch URL resolve failed, falling back to individual: \(error.localizedDescription)")
            // Fallback: download individually in parallel
            return await preloadIndividually(uncached)
        }

        // Step 2: Download all MP3s in parallel
        let downloaded = await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for item in uncached {
                guard let remoteURL = urlMap[item.id] else { continue }
                group.addTask {
                    await self.downloadMP3(id: item.id, from: remoteURL)
                }
            }
            var count = 0
            for await success in group {
                if success { count += 1 }
            }
            return count
        }

        let alreadyCached = items.count - uncached.count
        print("✅ [TTS] preloadBatch done: \(downloaded) downloaded, \(alreadyCached) already cached")
        return downloaded + alreadyCached
    }

    /// Fallback: preload items individually using the single API.
    private func preloadIndividually(_ items: [(id: String, text: String)]) async -> Int {
        await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for item in items {
                group.addTask {
                    await self.prepareAudio(id: item.id, text: item.text)
                }
            }
            var count = 0
            for await success in group {
                if success { count += 1 }
            }
            return count
        }
    }

    /// Download a single MP3 from a known remote URL to local cache.
    private func downloadMP3(id: String, from remoteURL: URL) async -> Bool {
        let result = await downloadWithDedup(id: id) {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            return data
        }
        return result != nil
    }

    /// Download MP3 from API to local Caches directory and populate cachedAudioURLs.
    private func downloadToLocal(id: String, text: String) async -> URL? {
        await downloadWithDedup(id: id) {
            let voiceId = VoiceManager.shared.selectedVoiceId
            let remoteURL = try await DailySpeakAPIService.shared.generateEnglishAudioURL(id: id, text: text, voiceId: voiceId)
            print("⬇️ [TTS] downloading audio: id=\(id)")
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            return data
        }
    }

    /// Ensures only one download per id at a time, uses atomic write.
    private func downloadWithDedup(id: String, fetch: @escaping () async throws -> Data) async -> URL? {
        let localURL = Self.cacheDirectory.appendingPathComponent("\(id).mp3")

        // Already cached in memory
        if cachedAudioURLs[id] != nil { return localURL }

        // Already on disk
        if FileManager.default.fileExists(atPath: localURL.path) {
            cachedAudioURLs[id] = localURL
            return localURL
        }

        // Join existing download if in progress
        if let existing = activeDownloads[id] {
            return await existing.value
        }

        // Start new download
        let task = Task<URL?, Never> {
            do {
                let data = try await fetch()
                // Atomic write: write to temp file, then move
                let tempURL = Self.cacheDirectory.appendingPathComponent("\(id)_\(UUID().uuidString).tmp")
                try data.write(to: tempURL)
                try? FileManager.default.removeItem(at: localURL)
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                cachedAudioURLs[id] = localURL
                print("✅ [TTS] cached: \(id) (\(data.count) bytes)")
                return localURL
            } catch {
                print("❌ [TTS] download failed: \(id) - \(error.localizedDescription)")
                return nil
            }
        }
        activeDownloads[id] = task
        let result = await task.value
        activeDownloads.removeValue(forKey: id)
        return result
    }

    var hasVisiblePlayback: Bool {
        playbackContext != nil && (activePlaybackID != nil || loadingPlaybackID != nil || pausedPlaybackID != nil)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    func togglePlayback(id: String, text: String, sourceLabel: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if loadingPlaybackID == id {
            stopPlayback()
            return
        }

        if activePlaybackID == id {
            pausePlayback()
            return
        }

        if pausedPlaybackID == id {
            resumePlayback()
            return
        }

        let context = PlaybackContext(id: id, text: trimmed, sourceLabel: sourceLabel)
        requestSequence += 1
        let currentRequest = requestSequence
        playbackContext = context
        stopCurrentPlayback(clearLoading: false, preserveContext: true)
        loadingPlaybackID = id
        pausedPlaybackID = nil
        currentTime = 0
        duration = 0

        if let cached = cachedAudioURLs[id] {
            print("ℹ️ [TTS] using cached english audio url: \(cached.absoluteString)")
            startPlayback(url: cached, context: context)
            return
        }

        print("⬆️ [TTS] request english audio: id=\(id) textLength=\(trimmed.count)")
        Task {
            let localURL = await self.downloadToLocal(id: id, text: trimmed)
            guard self.requestSequence == currentRequest else { return }
            if let localURL {
                self.startPlayback(url: localURL, context: context)
            } else {
                self.loadingPlaybackID = nil
                self.playbackContext = nil
                self.pausedPlaybackID = nil
                self.currentTime = 0
                self.duration = 0
            }
        }
    }

    func stopPlayback() {
        requestSequence += 1
        stopCurrentPlayback(clearLoading: true, preserveContext: false)
    }

    func pausePlayback() {
        guard activePlaybackID != nil else { return }
        player?.pause()
        pausedPlaybackID = activePlaybackID
        activePlaybackID = nil
    }

    func resumePlayback() {
        guard pausedPlaybackID != nil else { return }
        configureAudioSessionIfPossible()
        activePlaybackID = pausedPlaybackID
        pausedPlaybackID = nil
        player?.play()
    }

    func seekPlayback(to progress: Double) {
        guard playbackContext != nil, duration > 0 else { return }
        let clampedProgress = min(max(progress, 0), 1)
        let targetTime = CMTime(seconds: duration * clampedProgress, preferredTimescale: 600)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = duration * clampedProgress
    }

    func isPlaying(id: String) -> Bool {
        activePlaybackID == id
    }

    func isLoading(id: String) -> Bool {
        loadingPlaybackID == id
    }

    func isPaused(id: String) -> Bool {
        pausedPlaybackID == id
    }

    func isCurrent(id: String) -> Bool {
        playbackContext?.id == id
    }

    private func startPlayback(url: URL, context: PlaybackContext) {
        stopCurrentPlayback(clearLoading: false, preserveContext: true)
        configureAudioSessionIfPossible()

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.initial, .new]) { _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .unknown:
                    print("ℹ️ [TTS] player item status unknown: \(context.id)")
                case .readyToPlay:
                    print("✅ [TTS] player item ready: \(context.id)")
                case .failed:
                    print("❌ [TTS] player item failed: \(item.error?.localizedDescription ?? "unknown error") url=\(url.absoluteString)")
                    self.stopCurrentPlayback(clearLoading: true, preserveContext: false)
                @unknown default:
                    print("❌ [TTS] player item entered unknown future status: \(context.id)")
                }
            }
        }
        let player = AVPlayer(playerItem: item)
        self.player = player
        playbackContext = context
        activePlaybackID = context.id
        loadingPlaybackID = nil
        pausedPlaybackID = nil
        currentTime = 0
        duration = 0
        installTimeObserver(on: player)

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.stopCurrentPlayback(clearLoading: true, preserveContext: false)
            }
        }

        failedToPlayObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            print("❌ [TTS] failed to play to end: \(error?.localizedDescription ?? "unknown error") url=\(url.absoluteString)")
            Task { @MainActor [weak self] in
                self?.stopCurrentPlayback(clearLoading: true, preserveContext: false)
            }
        }

        print("⬆️ [TTS] playing english audio: \(context.id)")
        player.play()
    }

    private func stopCurrentPlayback(clearLoading: Bool, preserveContext: Bool) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failedToPlayObserver {
            NotificationCenter.default.removeObserver(failedToPlayObserver)
            self.failedToPlayObserver = nil
        }
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        statusObservation = nil

        player?.pause()
        player = nil
        activePlaybackID = nil
        pausedPlaybackID = nil
        if clearLoading {
            loadingPlaybackID = nil
        }
        if !preserveContext {
            playbackContext = nil
            currentTime = 0
            duration = 0
        }
        deactivateAudioSessionIfPossible()
    }

    private func installTimeObserver(on player: AVPlayer) {
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self, weak player] time in
            Task { @MainActor [weak self, weak player] in
                guard let self else { return }
                let seconds = time.seconds
                if seconds.isFinite {
                    self.currentTime = max(0, seconds)
                }
                if let itemDuration = player?.currentItem?.duration.seconds, itemDuration.isFinite, itemDuration > 0 {
                    self.duration = itemDuration
                }
            }
        }
    }

    private func configureAudioSessionIfPossible() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("❌ [TTS] failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSessionIfPossible() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Ignore teardown errors.
        }
    }
}
