import Foundation

private struct TranslateTextResponseDTO: Decodable {
    let translatedText: String
    let detectedSourceLang: String?
    let provider: String?
}

private struct EnglishTTSResponseDTO: Decodable {
    let id: String?
    let audioUrl: String
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

    func translateToChinese(englishText: String) async throws -> String {
        let response: APIEnvelope<TranslateTextResponseDTO> = try await APIClient.shared.request(
            "translate/text",
            method: "POST",
            body: [
                "text": englishText,
                "sourceLang": "en",
                "targetLang": "zh"
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

    func generateEnglishAudioURL(id: String, text: String, voiceId: String? = nil) async throws -> URL {
        var body: [String: String] = [
            "id": id,
            "text": text
        ]
        if let voiceId {
            body["voiceId"] = voiceId
        }
        let response: APIEnvelope<EnglishTTSResponseDTO> = try await APIClient.shared.request(
            "tts/english/mp3",
            method: "POST",
            body: body,
            requiresAuth: true
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        let trimmed = data.audioUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), !trimmed.isEmpty else {
            throw APIError.decoding
        }
        return url
    }
}
