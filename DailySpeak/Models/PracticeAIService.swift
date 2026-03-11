import Foundation

enum PracticeAIError: LocalizedError {
    case missingAuth
    case invalidResponse
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAuth:
            return "请先登录后再使用服务器 AI 能力。"
        case .invalidResponse:
            return "服务器返回内容为空，请稍后重试。"
        case let .serverMessage(message):
            return message
        }
    }
}

struct PracticeAIService {
    static let shared = PracticeAIService()

    private init() {}

    func translateToEnglish(nativeText: String, topic: String) async throws -> String {
        _ = topic
        try ensureAuthenticated()
        let response = try await DailySpeakAPIService.shared.translateToEnglish(text: nativeText)
        let normalized = response.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw PracticeAIError.invalidResponse
        }
        return normalized
    }

    func polishToSpokenEnglish(englishText: String, topic: String) async throws -> String {
        try ensureAuthenticated()
        let response = try await DailySpeakAPIService.shared.polishToSpokenEnglish(text: englishText, topic: topic)
        let normalized = response.polishedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw PracticeAIError.invalidResponse
        }
        return normalized
    }

    private func ensureAuthenticated() throws {
        let token = APIClient.shared.accessToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !token.isEmpty else {
            throw PracticeAIError.missingAuth
        }
    }
}
