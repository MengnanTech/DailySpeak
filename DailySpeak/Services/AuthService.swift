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

private struct EmailVerificationRequest: Encodable {
    let email: String
}

private struct EmailRegistrationRequest: Encodable {
    let email: String
    let password: String
    let verificationCode: String
}

private struct LoginRequestBody: Encodable {
    let email: String
    let password: String
}

private struct OAuthCallbackRequestBody: Encodable {
    let provider: String
    let identityToken: String
    let nonce: String
    let providerUserId: String
    let bundleId: String
    let email: String?
    let name: String?
}

private struct EmptyResponse: Decodable {}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    func sendEmailRegisterCode(email: String) async throws {
        let result: APIResult<EmptyResponse> = try await APIClient.shared.request(
            "auth/register/email/code",
            method: .post,
            body: EmailVerificationRequest(email: email)
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
    }

    func registerWithEmail(email: String, password: String, verificationCode: String) async throws -> String {
        let result: APIResult<String> = try await APIClient.shared.request(
            "auth/register/email",
            method: .post,
            body: EmailRegistrationRequest(email: email, password: password, verificationCode: verificationCode)
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let token = result.data?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            throw APIError.invalidResponse
        }
        return token
    }

    func login(email: String, password: String) async throws -> AuthResponseDTO {
        let result: APIResult<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/login",
            method: .post,
            body: LoginRequestBody(email: email, password: password)
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let data = result.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    func refresh() async throws -> AuthResponseDTO {
        let result: APIResult<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/refresh",
            method: .post,
            body: EmptyBody(),
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

    func oauthApple(idToken: String, rawNonce: String, appleUserID: String, email: String?, name: String?) async throws -> AuthResponseDTO {
        let result: APIResult<AuthResponseDTO> = try await APIClient.shared.request(
            "auth/oauth/callback",
            method: .post,
            body: OAuthCallbackRequestBody(
                provider: "APPLE",
                identityToken: idToken,
                nonce: rawNonce,
                providerUserId: appleUserID,
                bundleId: Bundle.main.bundleIdentifier ?? "",
                email: email,
                name: name
            )
        )
        if result.code != 200 {
            throw APIError.api(result.code, result.msg)
        }
        guard let data = result.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    func logout() async {
        let _: APIResult<EmptyResponse>? = try? await APIClient.shared.request(
            "auth/logout",
            method: .post,
            body: EmptyBody(),
            requiresAuth: true
        )
    }
}

private struct EmptyBody: Encodable {}
