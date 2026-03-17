import Foundation

private struct TranslateTextResponseDTO: Decodable {
    let translatedText: String
    let detectedSourceLang: String?
    let provider: String?
}

private struct PolishSpokenEnglishResponseDTO: Decodable {
    let polishedText: String
}

private struct EnglishTTSResponseDTO: Decodable {
    let id: String?
    let audioUrl: String
    let provider: String?
}

private struct EnglishTTSBatchResponseDTO: Decodable {
    let items: [EnglishTTSBatchItemDTO]
    let total: Int
    let cached: Int
    let generated: Int
}

private struct EnglishTTSBatchItemDTO: Decodable {
    let id: String?
    let audioUrl: String?
    let provider: String?
}

final class DailySpeakAPIService {
    static let shared = DailySpeakAPIService()

    private init() {}

    /// Device language as BCP-47 tag (e.g. "zh-Hans", "ja", "ko", "en-US").
    /// Strips country code but keeps script subtag: "zh-Hans-CN" → "zh-Hans", "ja-JP" → "ja".
    /// Backend is responsible for mapping this to provider-specific codes (DeepL/Google/etc).
    static var deviceLanguage: String {
        let tag = Locale.preferredLanguages.first ?? "zh-Hans"
        let parts = tag.components(separatedBy: "-")
        // Keep language + script (e.g. "zh-Hans"), drop country (e.g. "CN")
        // Script subtags are exactly 4 chars (Hans, Hant, Latn, Cyrl...)
        if parts.count >= 2, parts[1].count == 4 {
            return "\(parts[0])-\(parts[1])"
        }
        return parts[0]
    }

    /// 用户选择的翻译渠道 key
    static let translationProviderKey = "dailyspeak.translation.provider"

    /// 读取用户选择的翻译渠道，nil 表示用后端默认
    static var preferredProvider: String? {
        let val = UserDefaults.standard.string(forKey: translationProviderKey)
        return (val == nil || val == "auto") ? nil : val
    }

    /// 统一翻译接口。sourceLang 不传，后端自动检测。
    /// - provider: 翻译渠道，nil 则读用户偏好，偏好也没有则由后端决定
    func translate(text: String, targetLang: String, provider: String? = nil) async throws -> String {
        let resolvedProvider = provider ?? Self.preferredProvider
        var body: [String: Any] = [
            "text": text,
            "targetLang": targetLang,
        ]
        if let resolvedProvider { body["provider"] = resolvedProvider }

        let response: APIEnvelope<TranslateTextResponseDTO> = try await APIClient.shared.request(
            "translate/text",
            method: "POST",
            body: body,
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

    /// 任意语言 → 英文
    func translateToEnglish(nativeText: String, topic _: String, provider: String? = nil) async throws -> String {
        try await translate(text: nativeText, targetLang: "en-US", provider: provider)
    }

    /// 英文 → 用户设备母语
    func translateToNative(englishText: String, provider: String? = nil) async throws -> String {
        try await translate(text: englishText, targetLang: Self.deviceLanguage, provider: provider)
    }

    /// DeepSeek LLM 润色：任意语言输入 → 地道口语英文
    /// 后端接口：POST polish/spoken-english (走 DeepSeek，不走翻译引擎)
    func polishToSpokenEnglish(text: String, topic: String) async throws -> String {
        let response: APIEnvelope<PolishSpokenEnglishResponseDTO> = try await APIClient.shared.request(
            "polish/spoken-english",
            method: "POST",
            body: [
                "text": text,
                "topic": topic,
                "deviceLang": Self.deviceLanguage,
            ],
            requiresAuth: true
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        let result = data.polishedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else {
            throw APIError.decoding
        }
        return result
    }

    /// Batch resolve audio URLs for multiple items in one request.
    /// Returns a dictionary mapping id → remote audio URL.
    func generateEnglishAudioURLBatch(items: [(id: String, text: String)], voiceId: String? = nil) async throws -> [String: URL] {
        let requestItems: [[String: String]] = items.map { item in
            let dict: [String: String] = ["id": item.id, "text": item.text]
            return dict
        }
        var body: [String: Any] = ["items": requestItems]
        if let voiceId {
            body["voiceId"] = voiceId
        }
        let response: APIEnvelope<EnglishTTSBatchResponseDTO> = try await APIClient.shared.request(
            "tts/english/mp3/batch",
            method: "POST",
            body: body,
            requiresAuth: true
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        var result: [String: URL] = [:]
        for item in data.items {
            guard let id = item.id, let urlString = item.audioUrl else { continue }
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let url = URL(string: trimmed) else { continue }
            result[id] = url
        }
        return result
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
