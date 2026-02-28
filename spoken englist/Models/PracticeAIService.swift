import Foundation

enum PracticeAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "未配置 API Key。请在运行配置里设置 OPENAI_API_KEY 或写入 Info.plist 的 OPENAI_API_KEY。"
        case .invalidResponse:
            "API 返回内容为空，请稍后重试。"
        case let .serverMessage(message):
            message
        }
    }
}

struct PracticeAIService {
    static let shared = PracticeAIService()

    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let model = "gpt-4.1-mini"

    private init() {}

    func translateToEnglish(nativeText: String, topic: String) async throws -> String {
        let systemPrompt = """
        You are an IELTS speaking coach.
        Translate the user's native-language notes into clear English.
        Keep the meaning exactly, avoid adding new facts.
        Output only the translated English paragraph.
        """

        let userPrompt = """
        Topic: \(topic)
        Native input:
        \(nativeText)
        """

        return try await requestText(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.3)
    }

    func polishToSpokenEnglish(englishText: String, topic: String) async throws -> String {
        let systemPrompt = """
        You are an IELTS speaking coach.
        Rewrite the text into natural, idiomatic spoken English.
        Keep the same core meaning and keep it concise (about 120-180 words).
        Output only the polished spoken English paragraph.
        """

        let userPrompt = """
        Topic: \(topic)
        Draft English:
        \(englishText)
        """

        return try await requestText(systemPrompt: systemPrompt, userPrompt: userPrompt, temperature: 0.55)
    }

    private func requestText(systemPrompt: String, userPrompt: String, temperature: Double) async throws -> String {
        guard let apiKey = resolveAPIKey() else {
            throw PracticeAIError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ResponsesRequest(
                model: model,
                input: [
                    .init(role: "system", content: [.init(text: systemPrompt)]),
                    .init(role: "user", content: [.init(text: userPrompt)]),
                ],
                temperature: temperature
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PracticeAIError.invalidResponse
        }

        if (200..<300).contains(http.statusCode) {
            let decoded = try JSONDecoder().decode(ResponsesResponse.self, from: data)
            if let text = decoded.resolvedText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            throw PracticeAIError.invalidResponse
        }

        if let errorPayload = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            throw PracticeAIError.serverMessage(errorPayload.error.message)
        }

        throw PracticeAIError.serverMessage("API 请求失败（\(http.statusCode)）")
    }

    private func resolveAPIKey() -> String? {
        let bundleKey = (Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let bundleKey, !bundleKey.isEmpty {
            return bundleKey
        }

        let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let envKey, !envKey.isEmpty {
            return envKey
        }

        let userDefaultsKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let userDefaultsKey, !userDefaultsKey.isEmpty {
            return userDefaultsKey
        }

        return nil
    }
}

private struct ResponsesRequest: Encodable {
    let model: String
    let input: [InputMessage]
    let temperature: Double
}

private struct InputMessage: Encodable {
    let role: String
    let content: [InputContent]
}

private struct InputContent: Encodable {
    let type = "input_text"
    let text: String
}

private struct ResponsesResponse: Decodable {
    let output_text: String?
    let output: [OutputMessage]?

    var resolvedText: String? {
        if let output_text, !output_text.isEmpty {
            return output_text
        }

        let texts = output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .filter { !$0.isEmpty } ?? []
        if texts.isEmpty { return nil }
        return texts.joined(separator: "\n")
    }
}

private struct OutputMessage: Decodable {
    let content: [OutputContent]?
}

private struct OutputContent: Decodable {
    let text: String?
}

private struct ErrorEnvelope: Decodable {
    let error: ErrorMessage
}

private struct ErrorMessage: Decodable {
    let message: String
}
