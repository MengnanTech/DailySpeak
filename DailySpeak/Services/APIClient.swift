import Foundation

enum APIError: Error {
    case invalidURL
    case decoding
    case http(Int, String?)
    case api(Int, String?)
    case transport(String)
    case unknown
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效。"
        case .decoding:
            return "服务器返回无法解析。"
        case .http(let code, let message):
            if let message, !message.isEmpty {
                return "网络请求失败（\(code)）：\(message)"
            }
            return "网络请求失败（\(code)）。"
        case .api(_, let message):
            return message ?? "服务器处理失败，请稍后再试。"
        case .transport(let message):
            return message
        case .unknown:
            return "发生未知错误。"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let code: Int
    let requestId: String?
    let msg: String?
    let data: T?
}

struct APIConfig {
    static let baseURL = URL(string: "https://api.ikuon.com")!

    static var isConfigured: Bool {
        !(baseURL.host ?? "").isEmpty
    }
}

final class APIClient {
    static let shared = APIClient()

    private init() {}

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "dailyspeak.api.accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "dailyspeak.api.accessToken") }
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: [String: Any]? = nil,
        requiresAuth: Bool = false
    ) async throws -> APIEnvelope<T> {
        let data = try await send(path, method: method, queryItems: queryItems, body: body, requiresAuth: requiresAuth)
        do {
            return try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func send(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: [String: Any]?,
        requiresAuth: Bool
    ) async throws -> Data {
        guard var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        if requiresAuth, let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.http(http.statusCode, decodeHTTPErrorMessage(from: data))
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private func decodeHTTPErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = object["msg"] as? String, !message.isEmpty {
                return message
            }
            if let message = object["message"] as? String, !message.isEmpty {
                return message
            }
        }

        let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let raw, !raw.isEmpty {
            return raw
        }
        return nil
    }
}
