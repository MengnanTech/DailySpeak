import AuthenticationServices
import Foundation

extension AppState {
    private enum AuthStorageKeys {
        static let mode = "auth.mode"
        static let userID = "auth.apple.userID"
        static let displayName = "auth.displayName"
        static let email = "auth.email"
        static let backendUserID = "auth.backend.userID"
        static let backendRole = "auth.backend.role"
        static let onboardingCompleted = "auth.onboardingCompleted"
        static let initialChoiceCompleted = "auth.initialChoiceCompleted"
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        hasCompletedInitialAuthChoice = false
        persistAuthState()
        AppEventReporter.shared.report(.onboardingCompleted)
    }

    func completeInitialAuthChoiceAsGuest() {
        APIClient.shared.accessToken = nil
        authMode = .guest
        authUserID = nil
        authDisplayName = nil
        authEmail = nil
        backendUserID = nil
        backendRole = nil
        hasCompletedInitialAuthChoice = true
        persistAuthState()
        AppEventReporter.shared.report(.guestModeSelected)
    }

    @MainActor
    func loginWithEmail(email: String, password: String) async throws {
        let response = try await AuthService.shared.login(email: email, password: password)
        applyBackendAuthResponse(response, desiredMode: .email, appleUserID: nil)
    }

    @MainActor
    func registerWithEmail(email: String, password: String, verificationCode: String) async throws {
        let token = try await AuthService.shared.registerWithEmail(email: email, password: password, verificationCode: verificationCode)
        APIClient.shared.accessToken = token
        let response = try await AuthService.shared.refresh()
        applyBackendAuthResponse(response, desiredMode: .email, appleUserID: nil)
    }

    func configureAppleLoginRequest(_ request: ASAuthorizationAppleIDRequest) {
        isAppleSignInInProgress = true
        request.requestedScopes = [.fullName, .email]
        let raw = AppleSignInNonce.randomNonceString()
        UserDefaults.standard.set(raw, forKey: "auth.apple.rawNonce")
        request.nonce = AppleSignInNonce.sha256(raw)
    }

    @MainActor
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> AppleSignInOutcome {
        defer { isAppleSignInInProgress = false }
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return .failure(message: "Apple 登录返回无效。")
            }
            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let rawNonce = UserDefaults.standard.string(forKey: "auth.apple.rawNonce"),
                  !rawNonce.isEmpty else {
                return .failure(message: "Apple 登录数据不完整。")
            }
            do {
                let response = try await AuthService.shared.oauthApple(
                    idToken: idToken,
                    rawNonce: rawNonce,
                    appleUserID: credential.user,
                    email: credential.email,
                    name: PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                )
                applyBackendAuthResponse(response, desiredMode: .apple, appleUserID: credential.user)
                return .success
            } catch {
                signOut()
                return .failure(message: error.localizedDescription)
            }
        case let .failure(error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return .cancelled
            }
            return .failure(message: error.localizedDescription)
        }
    }

    @MainActor
    private func applyBackendAuthResponse(_ response: AuthResponseDTO, desiredMode: AuthMode, appleUserID: String?) {
        let token = (response.accessToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty {
            APIClient.shared.accessToken = token
        }
        authMode = desiredMode
        AppState.currentAuthModeRawValue = desiredMode.rawValue
        authUserID = desiredMode == .apple ? appleUserID : nil
        authDisplayName = response.name ?? authDisplayName
        authEmail = response.email ?? authEmail
        backendUserID = response.id
        backendRole = response.role
        hasCompletedOnboarding = true
        hasCompletedInitialAuthChoice = true
        persistAuthState()
        AppEventReporter.shared.report(
            .authSucceeded,
            properties: [
                "mode": desiredMode.rawValue,
                "has_email": response.email == nil ? "false" : "true",
            ]
        )
    }

    @MainActor
    func signOut() {
        APIClient.shared.accessToken = nil
        authMode = .guest
        authUserID = nil
        authDisplayName = nil
        authEmail = nil
        backendUserID = nil
        backendRole = nil
        hasCompletedInitialAuthChoice = true
        persistAuthState()
        AppEventReporter.shared.report(.signedOut)
    }

    func loadAuthState() {
        let defaults = UserDefaults.standard
        authMode = AuthMode(rawValue: defaults.string(forKey: AuthStorageKeys.mode) ?? AuthMode.guest.rawValue) ?? .guest
        authUserID = defaults.string(forKey: AuthStorageKeys.userID)
        authDisplayName = defaults.string(forKey: AuthStorageKeys.displayName)
        authEmail = defaults.string(forKey: AuthStorageKeys.email)
        backendUserID = defaults.string(forKey: AuthStorageKeys.backendUserID)
        backendRole = defaults.string(forKey: AuthStorageKeys.backendRole)
        hasCompletedOnboarding = defaults.bool(forKey: AuthStorageKeys.onboardingCompleted)
        if defaults.object(forKey: AuthStorageKeys.initialChoiceCompleted) == nil {
            hasCompletedInitialAuthChoice = defaults.bool(forKey: Constants.StorageKeys.hasLaunchedBefore)
        } else {
            hasCompletedInitialAuthChoice = defaults.bool(forKey: AuthStorageKeys.initialChoiceCompleted)
        }

        if (APIClient.shared.accessToken ?? "").isEmpty {
            authMode = .guest
        }
        AppState.currentAuthModeRawValue = authMode.rawValue
    }

    func persistAuthState() {
        let defaults = UserDefaults.standard
        AppState.currentAuthModeRawValue = authMode.rawValue
        defaults.set(authMode.rawValue, forKey: AuthStorageKeys.mode)
        defaults.set(authUserID, forKey: AuthStorageKeys.userID)
        defaults.set(authDisplayName, forKey: AuthStorageKeys.displayName)
        defaults.set(authEmail, forKey: AuthStorageKeys.email)
        defaults.set(backendUserID, forKey: AuthStorageKeys.backendUserID)
        defaults.set(backendRole, forKey: AuthStorageKeys.backendRole)
        defaults.set(hasCompletedOnboarding, forKey: AuthStorageKeys.onboardingCompleted)
        defaults.set(hasCompletedInitialAuthChoice, forKey: AuthStorageKeys.initialChoiceCompleted)
        defaults.set(true, forKey: Constants.StorageKeys.hasLaunchedBefore)
    }
}
