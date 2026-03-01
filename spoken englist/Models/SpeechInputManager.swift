import AVFoundation
import Foundation
import Speech
internal import Combine

@MainActor
final class SpeechInputManager: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var lastError: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasRequestedAuthorization = false

    override init() {
        let locale = Locale.current.identifier
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
            return
        }

        do {
            let granted = await requestAuthorizationIfNeeded()
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
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        if !hasRequestedAuthorization {
            hasRequestedAuthorization = true
        }

        let speechAuth: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micAuth: Bool = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return speechAuth == .authorized && micAuth
    }

    private func startRecording() throws {
        stopRecording()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        guard let speechRecognizer else {
            throw NSError(domain: "SpeechInputManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持语音识别"])
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stopRecording()
                    }
                }
            }

            if let error {
                Task { @MainActor in
                    self.lastError = "语音识别失败：\(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }

        isRecording = true
    }
}
