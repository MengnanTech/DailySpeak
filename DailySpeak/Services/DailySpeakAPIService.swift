import Foundation

private struct TranslateTextResponseDTO: Decodable {
    let translatedText: String
    let detectedSourceLang: String?
    let provider: String?
}

final class DailySpeakAPIService {
    static let shared = DailySpeakAPIService()

    private init() {}

    func translateToEnglish(nativeText: String, topic _: String) async throws -> String {
        let response: APIEnvelope<TranslateTextResponseDTO> = try await APIClient.shared.request(
            "translate/text",
            method: "POST",
            body: [
                "text": nativeText,
                "sourceLang": "zh",
                "targetLang": "en"
            ],
            requiresAuth: true
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        let text = data.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw APIError.decoding
        }
        return text
    }

    func polishToSpokenEnglish(englishText _: String, topic _: String) async throws -> String {
        throw APIError.transport("后端当前没有 DailySpeak polish 接口，客户端已停止调用该能力。")
    }
}
