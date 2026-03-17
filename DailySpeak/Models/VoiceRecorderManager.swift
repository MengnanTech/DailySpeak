import AVFoundation
import Combine
import Foundation

/// Pure audio recorder + playback for self-practice.
/// Records user's voice to a file and plays it back — no speech recognition.
@MainActor
final class VoiceRecorderManager: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case playing
    }

    @Published var state: State = .idle
    @Published var lastError: String?
    @Published var hasRecording = false
    /// Elapsed recording time in seconds.
    @Published var recordingDuration: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingURL: URL?
    private var durationTimer: Timer?

    /// Unique key used to persist recordings per practice task.
    private let storageKey: String

    init(storageKey: String = "") {
        self.storageKey = storageKey
        if !storageKey.isEmpty {
            let url = Self.fileURL(for: storageKey)
            hasRecording = FileManager.default.fileExists(atPath: url.path)
            recordingURL = url
        }
    }

    // MARK: - Public

    func toggleRecording() async {
        if state == .recording {
            stopRecording()
            return
        }
        if state == .playing {
            stopPlayback()
        }

        do {
            let granted = await requestMicPermission()
            guard granted else {
                lastError = "麦克风权限未开启，请在系统设置中允许。"
                return
            }
            try startRecording()
        } catch {
            stopRecording()
            lastError = "启动录音失败：\(error.localizedDescription)"
        }
    }

    func togglePlayback() {
        if state == .playing {
            stopPlayback()
            return
        }
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = playbackDelegate
            audioPlayer.play()
            player = audioPlayer
            state = .playing
        } catch {
            lastError = "播放失败：\(error.localizedDescription)"
        }
    }

    func stopAll() {
        stopRecording()
        stopPlayback()
    }

    func deleteRecording() {
        stopAll()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        hasRecording = false
        recordingDuration = 0
    }

    // MARK: - Private

    private func startRecording() throws {
        stopAll()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let url = Self.fileURL(for: storageKey)
        recordingURL = url

        // Create parent directory if needed
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder.record()
        recorder = audioRecorder
        state = .recording
        lastError = nil
        recordingDuration = 0

        // Timer to track elapsed recording time
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state == .recording else { return }
                self.recordingDuration = self.recorder?.currentTime ?? 0
            }
        }
    }

    private func stopRecording() {
        durationTimer?.invalidate()
        durationTimer = nil

        guard let recorder else { return }
        if recorder.isRecording {
            recorder.stop()
            recordingDuration = recorder.currentTime
        }
        self.recorder = nil

        if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
            hasRecording = true
        }
        if state == .recording { state = .idle }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        if state == .playing { state = .idle }
    }

    private func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Playback delegate

    private lazy var playbackDelegate = PlaybackDelegate { [weak self] in
        Task { @MainActor [weak self] in
            self?.state = .idle
        }
    }

    private final class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) { onFinish() }
    }

    // MARK: - File path

    private static func fileURL(for key: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice-recordings", isDirectory: true)
        let safeName = key.isEmpty ? "temp" : key
        return dir.appendingPathComponent("\(safeName).m4a")
    }
}
