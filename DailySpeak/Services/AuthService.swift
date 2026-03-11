import Foundation

struct AuthResponseDTO: Decodable {
    let id: String?
    let email: String?
    let name: String?
    let accessToken: String?
    let expiresIn: Int64?
    let role: String?
    let isNewUser: Bool?
}

struct EmptyDTO: Decodable {}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    func sendEmailRegisterCode(email: String) async throws {
        let response: APIEnvelope<EmptyDTO> = try await APIClient.shared.request(
            "auth/register/email/code",
            method: "POST",
            body: ["email": email]
        )
        guard response.code == 200 else {
            throw APIError.api(response.code, response.msg)
        }
    }

    func registerWithEmail(email: String, password: String, verificationCode: String) async throws -> String {
        let response: APIEnvelope<String> = try await APIClient.shared.request(
            "auth/register/email",
            method: "POST",
            body: [
                "email": email,
                "password": password,
                "verificationCode": verificationCode
            ]
        )
        guard response.code == 200 else {
            throw APIError.api(response.code, response.msg)
        }
        let token = (response.data ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw APIError.unknown
        }
        return token
    }

    func login(email: String, password: String) async throws -> AuthResponseDTO {
        let response: APIEnvelope<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/login",
            method: "POST",
            body: [
                "email": email,
                "password": password
            ]
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        return data
    }

    func refresh() async throws -> AuthResponseDTO {
        let response: APIEnvelope<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/refresh",
            method: "POST",
            body: [:],
            requiresAuth: true
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        return data
    }

    func oauthApple(idToken: String, rawNonce: String, appleUserID: String, email: String?, name: String?) async throws -> AuthResponseDTO {
        var payload: [String: Any] = [
            "provider": "APPLE",
            "identityToken": idToken,
            "nonce": rawNonce,
            "providerUserId": appleUserID,
            "bundleId": Bundle.main.bundleIdentifier ?? ""
        ]
        if let email, !email.isEmpty {
            payload["email"] = email
        }
        if let name, !name.isEmpty {
            payload["name"] = name
        }

        let response: APIEnvelope<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/oauth/callback",
            method: "POST",
            body: payload
        )
        guard response.code == 200, let data = response.data else {
            throw APIError.api(response.code, response.msg)
        }
        return data
    }

    func logout() async {
        do {
            let response: APIEnvelope<EmptyDTO> = try await APIClient.shared.request(
                "auth/logout",
                method: "POST",
                body: [:],
                requiresAuth: true
            )
            if response.code != 200 {
                return
            }
        } catch {
            return
        }
    }
}
