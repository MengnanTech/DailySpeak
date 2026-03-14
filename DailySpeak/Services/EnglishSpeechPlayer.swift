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

    private override init() {
        super.init()
    }

    static func playbackID(for text: String, category: String = "english") -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(category)-\(AppleSignInNonce.sha256(normalized))"
    }

    func clearAudioCache() {
        cachedAudioURLs.removeAll()
        cachedAudioDurations.removeAll()
    }

    func isAudioCached(id: String) -> Bool {
        cachedAudioURLs[id] != nil
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
        do {
            let voiceId = VoiceManager.shared.selectedVoiceId
            let remoteURL = try await DailySpeakAPIService.shared.generateEnglishAudioURL(id: id, text: trimmed, voiceId: voiceId)
            print("⬇️ [TTS] downloading audio to local: id=\(id)")
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(id).mp3")
            try data.write(to: localURL)
            cachedAudioURLs[id] = localURL

            // Probe duration
            let asset = AVAsset(url: localURL)
            let cmDuration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(cmDuration)
            if seconds.isFinite && seconds > 0 {
                cachedAudioDurations[id] = seconds
            }
            print("✅ [TTS] prepared audio (local): id=\(id) size=\(data.count) duration=\(String(format: "%.1f", seconds))s")
            return true
        } catch {
            print("❌ [TTS] prepare failed: \(error.localizedDescription)")
            return false
        }
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
            do {
                let voiceId = VoiceManager.shared.selectedVoiceId
                let url = try await DailySpeakAPIService.shared.generateEnglishAudioURL(id: id, text: trimmed, voiceId: voiceId)
                await MainActor.run {
                    guard self.requestSequence == currentRequest else { return }
                    self.cachedAudioURLs[id] = url
                    print("✅ [TTS] english audio url ready: \(url.absoluteString)")
                    self.startPlayback(url: url, context: context)
                }
            } catch {
                await MainActor.run {
                    guard self.requestSequence == currentRequest else { return }
                    self.loadingPlaybackID = nil
                    self.playbackContext = nil
                    self.pausedPlaybackID = nil
                    self.currentTime = 0
                    self.duration = 0
                    print("❌ [TTS] failed to load english speech: \(error.localizedDescription)")
                }
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
