import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case http(Int)
    case api(Int, String?)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "API 地址无效。"
        case .invalidResponse:
            return "服务器返回了无效数据。"
        case let .http(code):
            return "网络请求失败（\(code)）。"
        case let .api(_, message):
            return message ?? "服务器暂时不可用。"
        case let .transport(message):
            return message
        }
    }
}

struct APIResult<T: Decodable>: Decodable {
    let code: Int
    let requestId: String?
    let msg: String?
    let data: T?
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct APIConfig {
    static let baseURL = URL(string: "https://api.ikuon.com")!
}

final class APIClient {
    static let shared = APIClient()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "api_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "api_access_token") }
    }

    private init() {}

    func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .get,
        body: Body? = nil,
        requiresAuth: Bool = false
    ) async throws -> APIResult<T> {
        guard let url = URL(string: normalizedPath(path), relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyDefaultHeaders(to: &request)

        if requiresAuth, let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
        do {
            return try decoder.decode(APIResult<T>.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    func sendDataRequest(
        _ path: String,
        method: HTTPMethod = .post,
        jsonBody: Data? = nil,
        requiresAuth: Bool = false,
        contentType: String = "application/json",
        accept: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: normalizedPath(path), relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if let accept {
            request.setValue(accept, forHTTPHeaderField: "Accept")
        }
        applyDefaultHeaders(to: &request)

        if requiresAuth, let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = jsonBody

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
        return (data, http)
    }

    func uploadMultipart<T: Decodable>(
        _ path: String,
        fileURL: URL,
        fieldName: String = "files",
        mimeType: String,
        requiresAuth: Bool = true
    ) async throws -> APIResult<T> {
        guard let url = URL(string: normalizedPath(path), relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyDefaultHeaders(to: &request)
        if requiresAuth, let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let filename = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
        do {
            return try decoder.decode(APIResult<T>.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func normalizedPath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        return "/" + path
    }

    private func applyDefaultHeaders(to request: inout URLRequest) {
        let bundle = Bundle.main
        request.setValue("ios", forHTTPHeaderField: "X-App-Platform")
        request.setValue(bundle.bundleIdentifier ?? "DailySpeak", forHTTPHeaderField: "X-App-Bundle-ID")
        request.setValue(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev", forHTTPHeaderField: "X-App-Version")
        request.setValue(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "dev", forHTTPHeaderField: "X-App-Build")
        request.setValue(Locale.current.identifier, forHTTPHeaderField: "X-App-Locale")
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-App-Timezone")
        #if canImport(UIKit)
        request.setValue(UIDevice.current.systemVersion, forHTTPHeaderField: "X-OS-Version")
        request.setValue(UIDevice.current.model, forHTTPHeaderField: "X-Device-Model")
        #endif
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
