import AVFoundation
import Combine
import Foundation

@MainActor
final class EnglishSpeechPlayer: NSObject, ObservableObject {
    static let shared = EnglishSpeechPlayer()

    @Published private(set) var activePlaybackID: String?
    @Published private(set) var loadingPlaybackID: String?

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var failedToPlayObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var cachedAudioURLs: [String: URL] = [:]
    private var requestSequence = 0

    private override init() {
        super.init()
    }

    static func playbackID(for text: String, category: String = "english") -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(category)-\(AppleSignInNonce.sha256(normalized))"
    }

    func togglePlayback(id: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if activePlaybackID == id || loadingPlaybackID == id {
            stopPlayback()
            return
        }

        requestSequence += 1
        let currentRequest = requestSequence
        stopCurrentPlayback(clearLoading: false)
        loadingPlaybackID = id

        if let cached = cachedAudioURLs[id] {
            print("ℹ️ [TTS] using cached english audio url: \(cached.absoluteString)")
            startPlayback(url: cached, id: id)
            return
        }

        print("⬆️ [TTS] request english audio: id=\(id) textLength=\(trimmed.count)")
        Task {
            do {
                let url = try await DailySpeakAPIService.shared.generateEnglishAudioURL(id: id, text: trimmed)
                await MainActor.run {
                    guard self.requestSequence == currentRequest else { return }
                    self.cachedAudioURLs[id] = url
                    print("✅ [TTS] english audio url ready: \(url.absoluteString)")
                    self.startPlayback(url: url, id: id)
                }
            } catch {
                await MainActor.run {
                    guard self.requestSequence == currentRequest else { return }
                    self.loadingPlaybackID = nil
                    print("❌ [TTS] failed to load english speech: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopPlayback() {
        requestSequence += 1
        stopCurrentPlayback(clearLoading: true)
    }

    func isPlaying(id: String) -> Bool {
        activePlaybackID == id
    }

    func isLoading(id: String) -> Bool {
        loadingPlaybackID == id
    }

    private func startPlayback(url: URL, id: String) {
        stopCurrentPlayback(clearLoading: false)
        configureAudioSessionIfPossible()

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.initial, .new]) { _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .unknown:
                    print("ℹ️ [TTS] player item status unknown: \(id)")
                case .readyToPlay:
                    print("✅ [TTS] player item ready: \(id)")
                case .failed:
                    print("❌ [TTS] player item failed: \(item.error?.localizedDescription ?? "unknown error") url=\(url.absoluteString)")
                    self.stopCurrentPlayback(clearLoading: true)
                @unknown default:
                    print("❌ [TTS] player item entered unknown future status: \(id)")
                }
            }
        }
        let player = AVPlayer(playerItem: item)
        self.player = player
        activePlaybackID = id
        loadingPlaybackID = nil

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.stopCurrentPlayback(clearLoading: true)
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
                self?.stopCurrentPlayback(clearLoading: true)
            }
        }

        print("⬆️ [TTS] playing english audio: \(id)")
        player.play()
    }

    private func stopCurrentPlayback(clearLoading: Bool) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failedToPlayObserver {
            NotificationCenter.default.removeObserver(failedToPlayObserver)
            self.failedToPlayObserver = nil
        }
        statusObservation = nil

        player?.pause()
        player = nil
        activePlaybackID = nil
        if clearLoading {
            loadingPlaybackID = nil
        }
        deactivateAudioSessionIfPossible()
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
