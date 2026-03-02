import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechInputManager: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var lastError: String?

    private var audioEngine: AVAudioEngine?
    private let speechRecognizer: SFSpeechRecognizer?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
            return
        }

        do {
            let granted = await requestAuthorization()
            guard granted else {
                lastError = "语音权限未开启，请在系统设置中允许麦克风和语音识别。"
                return
            }
            try startRecording()
        } catch {
            stopRecording()
            lastError = "启动录音失败：\(error.localizedDescription)"
        }
    }

    func stopRecording() {
        // 1. Stop the engine first (stops the tap callback)
        let engine = audioEngine
        audioEngine = nil

        if let engine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        // 2. End the recognition request (signals no more audio)
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 3. Cancel the task last
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
    }

    // MARK: - Authorization

    private func requestAuthorization() async -> Bool {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let speechGranted: Bool

        if speechStatus == .notDetermined {
            speechGranted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        } else {
            speechGranted = speechStatus == .authorized
        }

        guard speechGranted else { return false }

        let micGranted: Bool = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return micGranted
    }

    // MARK: - Recording

    private func startRecording() throws {
        // Clean up any previous session
        stopRecording()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw NSError(
                domain: "SpeechInputManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "当前设备不支持语音识别"]
            )
        }

        // Install audio tap — runs on audio thread, only touches `request`
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()
        isRecording = true

        // Recognition callback — dispatches UI updates to MainActor
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            let isFinal = result?.isFinal ?? false
            let text = result?.bestTranscription.formattedString
            let errorMsg = error?.localizedDescription

            Task { @MainActor [weak self] in
                guard let self else { return }

                if let text {
                    self.transcript = text
                }

                if let errorMsg, !isFinal {
                    self.lastError = "语音识别失败：\(errorMsg)"
                }

                if isFinal || error != nil {
                    self.stopRecording()
                }
            }
        }
    }
}
