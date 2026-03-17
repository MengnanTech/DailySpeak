import AVFoundation
import Combine
import Foundation

/// Pure audio recorder + playback for self-practice.
/// Supports multiple recordings per task.
@MainActor
final class VoiceRecorderManager: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case playing(index: Int)
    }

    @Published var state: State = .idle
    @Published var lastError: String?
    @Published var hasRecording = false
    /// Elapsed recording time in seconds.
    @Published var recordingDuration: TimeInterval = 0
    /// All recorded audio file URLs.
    @Published var recordings: [RecordingEntry] = []

    struct RecordingEntry: Identifiable {
        let id: Int
        let url: URL
        let duration: TimeInterval
    }

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var durationTimer: Timer?

    /// Unique key used to persist recordings per practice task.
    private let storageKey: String

    init(storageKey: String = "") {
        self.storageKey = storageKey
        loadExistingRecordings()
    }

    // MARK: - Public

    func toggleRecording() async {
        if state == .recording {
            stopRecording()
            return
        }
        stopPlayback()

        do {
            let granted = await requestMicPermission()
            guard granted else {
                lastError = String(localized: "Microphone permission not enabled. Please allow it in Settings.")
                return
            }
            try startRecording()
        } catch {
            stopRecording()
            lastError = String(localized: "Failed to start recording: \(error.localizedDescription)")
        }
    }

    func togglePlayback(at index: Int) {
        if case .playing(let currentIndex) = state, currentIndex == index {
            stopPlayback()
            return
        }
        stopPlayback()

        guard index < recordings.count else { return }
        let url = recordings[index].url
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = playbackDelegate
            audioPlayer.play()
            player = audioPlayer
            state = .playing(index: index)
        } catch {
            lastError = String(localized: "Playback failed: \(error.localizedDescription)")
        }
    }

    func stopAll() {
        if state == .recording { stopRecording() }
        stopPlayback()
    }

    func deleteRecording(at index: Int) {
        stopAll()
        guard index < recordings.count else { return }
        let entry = recordings[index]
        try? FileManager.default.removeItem(at: entry.url)
        recordings.remove(at: index)
        // Rename remaining files to keep indices sequential
        renumberRecordings()
        hasRecording = !recordings.isEmpty
    }

    // MARK: - Private

    private func startRecording() throws {
        stopAll()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let nextIndex = recordings.count
        let url = Self.fileURL(for: storageKey, index: nextIndex)

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
        let duration = recorder.currentTime
        let url = recorder.url
        if recorder.isRecording {
            recorder.stop()
        }
        self.recorder = nil

        if FileManager.default.fileExists(atPath: url.path), duration > 0.5 {
            let entry = RecordingEntry(id: recordings.count, url: url, duration: duration)
            recordings.append(entry)
            hasRecording = true
        }
        if state == .recording { state = .idle }
        recordingDuration = 0
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        if case .playing = state { state = .idle }
    }

    private func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Persistence

    private func loadExistingRecordings() {
        guard !storageKey.isEmpty else { return }
        var entries: [RecordingEntry] = []
        for i in 0..<100 {
            let url = Self.fileURL(for: storageKey, index: i)
            if FileManager.default.fileExists(atPath: url.path) {
                // Get duration
                let duration: TimeInterval
                if let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
                    duration = audioPlayer.duration
                } else {
                    duration = 0
                }
                entries.append(RecordingEntry(id: i, url: url, duration: duration))
            } else {
                break
            }
        }
        recordings = entries
        hasRecording = !entries.isEmpty
    }

    private func renumberRecordings() {
        var newEntries: [RecordingEntry] = []
        for (newIndex, entry) in recordings.enumerated() {
            let newURL = Self.fileURL(for: storageKey, index: newIndex)
            if entry.url != newURL {
                try? FileManager.default.moveItem(at: entry.url, to: newURL)
            }
            newEntries.append(RecordingEntry(id: newIndex, url: newURL, duration: entry.duration))
        }
        recordings = newEntries
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

    private static func fileURL(for key: String, index: Int) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice-recordings", isDirectory: true)
        let safeName = key.isEmpty ? "temp" : key
        return dir.appendingPathComponent("\(safeName)_\(index).m4a")
    }

    /// Migration: check for old single-file format and convert
    static func migrateIfNeeded(storageKey: String) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice-recordings", isDirectory: true)
        let oldURL = dir.appendingPathComponent("\(storageKey).m4a")
        let newURL = dir.appendingPathComponent("\(storageKey)_0.m4a")
        if FileManager.default.fileExists(atPath: oldURL.path) && !FileManager.default.fileExists(atPath: newURL.path) {
            try? FileManager.default.moveItem(at: oldURL, to: newURL)
        }
    }
}
