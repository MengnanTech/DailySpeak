import Foundation

struct DailySpeakTranslationResponse: Decodable {
    let translatedText: String
    let detectedSourceLang: String?
    let provider: String?
}

struct DailySpeakPolishResponse: Decodable {
    let polishedText: String
    let provider: String?
}

final class DailySpeakAPIService {
    static let shared = DailySpeakAPIService()

    private let encoder = JSONEncoder()

    private init() {}

    func translateToEnglish(text: String) async throws -> DailySpeakTranslationResponse {
        let result: APIResult<DailySpeakTranslationResponse> = try await APIClient.shared.request(
            "translate/text",
            method: .post,
            body: TranslateTextRequest(text: text, sourceLang: "auto", targetLang: "en"),
            requiresAuth: true
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let data = result.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    func polishToSpokenEnglish(text: String, topic: String) async throws -> DailySpeakPolishResponse {
        let result: APIResult<DailySpeakPolishResponse> = try await APIClient.shared.request(
            "api/dailyspeak/polish",
            method: .post,
            body: PolishRequest(text: text, topic: topic),
            requiresAuth: true
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let data = result.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    func synthesizeSpeech(text: String, voiceId: String? = nil, locale: String = "en-US") async throws -> Data {
        let request = TTSRequest(text: text, voiceId: voiceId, locale: locale)
        let body = try encoder.encode(request)
        let (data, _) = try await APIClient.shared.sendDataRequest(
            "api/dailyspeak/tts",
            method: .post,
            jsonBody: body,
            requiresAuth: true,
            contentType: "application/json",
            accept: "audio/mpeg"
        )
        if data.isEmpty {
            throw APIError.invalidResponse
        }
        return data
    }

    func uploadAudio(fileURL: URL) async throws -> String {
        let result: APIResult<[String]> = try await APIClient.shared.uploadMultipart(
            "api/file/r2/upload",
            fileURL: fileURL,
            mimeType: resolveMimeType(for: fileURL)
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let url = result.data?.first, !url.isEmpty else {
            throw APIError.invalidResponse
        }
        return url
    }

    private func resolveMimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "m4a":
            return "audio/m4a"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "caf":
            return "audio/x-caf"
        default:
            return "application/octet-stream"
        }
    }
}

private struct TranslateTextRequest: Encodable {
    let text: String
    let sourceLang: String
    let targetLang: String
}

private struct PolishRequest: Encodable {
    let text: String
    let topic: String
}

private struct TTSRequest: Encodable {
    let text: String
    let voiceId: String?
    let locale: String
}
