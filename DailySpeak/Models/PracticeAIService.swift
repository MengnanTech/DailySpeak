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

    func translateToEnglish(nativeText: String, topic: String) async throws -> String {
        try await DailySpeakAPIService.shared.translateToEnglish(nativeText: nativeText, topic: topic)
    }

    func polishToSpokenEnglish(englishText: String, topic: String) async throws -> String {
        try await DailySpeakAPIService.shared.polishToSpokenEnglish(englishText: englishText, topic: topic)
    }
}
