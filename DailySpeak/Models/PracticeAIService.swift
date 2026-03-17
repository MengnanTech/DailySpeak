import Foundation

enum PracticeAIError: LocalizedError {
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case let .serverMessage(message):
            message
        }
    }
}

struct PracticeAIService {
    static let shared = PracticeAIService()

    private init() {}

    /// 纯翻译（机器翻译引擎，不走LLM）
    func translateToEnglish(nativeText: String, topic: String) async throws -> String {
        try await DailySpeakAPIService.shared.translateToEnglish(nativeText: nativeText, topic: topic)
    }

    /// AI润色：任意语言 → 地道口语英文（DeepSeek LLM）
    func polishToSpokenEnglish(text: String, topic: String) async throws -> String {
        try await DailySpeakAPIService.shared.polishToSpokenEnglish(text: text, topic: topic)
    }
}
