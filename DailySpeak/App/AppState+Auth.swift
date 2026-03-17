import Foundation
import AuthenticationServices

extension AppState {
    private enum AuthStorageKeys {
        static let mode = "dailyspeak.auth.mode"
        static let userID = "dailyspeak.auth.apple.userID"
        static let displayName = "dailyspeak.auth.displayName"
        static let email = "dailyspeak.auth.email"
        static let backendUserID = "dailyspeak.auth.backend.userID"
        static let backendRole = "dailyspeak.auth.backend.role"
        static let initialChoiceCompleted = "dailyspeak.auth.initialChoiceCompleted"
    }

    var isLoggedIn: Bool {
        authMode != .guest && !(APIClient.shared.accessToken ?? "").isEmpty
    }

    var shouldShowInitialAuthChoice: Bool {
        !hasCompletedInitialAuthChoice
    }

    func loadAuthState() {
        let defaults = UserDefaults.standard
        let rawMode = defaults.string(forKey: AuthStorageKeys.mode) ?? AuthMode.guest.rawValue
        authMode = AuthMode(rawValue: rawMode) ?? .guest
        authUserID = defaults.string(forKey: AuthStorageKeys.userID)
        authDisplayName = defaults.string(forKey: AuthStorageKeys.displayName)
        authEmail = defaults.string(forKey: AuthStorageKeys.email)
        backendUserID = defaults.string(forKey: AuthStorageKeys.backendUserID)
        backendRole = defaults.string(forKey: AuthStorageKeys.backendRole)
        if defaults.object(forKey: AuthStorageKeys.initialChoiceCompleted) == nil {
            hasCompletedInitialAuthChoice = defaults.bool(forKey: Constants.StorageKeys.hasLaunchedBefore)
        } else {
            hasCompletedInitialAuthChoice = defaults.bool(forKey: AuthStorageKeys.initialChoiceCompleted)
        }

        if (APIClient.shared.accessToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authMode = .guest
            authUserID = nil
            backendUserID = nil
            backendRole = nil
        }

        if authMode == .apple {
            let userID = authUserID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if userID.isEmpty {
                authMode = .guest
                authUserID = nil
                authDisplayName = nil
                authEmail = nil
            }
        }

        persistAuthState()
    }

    func persistAuthState() {
        let defaults = UserDefaults.standard
        defaults.set(authMode.rawValue, forKey: AuthStorageKeys.mode)
        defaults.set(authUserID, forKey: AuthStorageKeys.userID)
        defaults.set(authDisplayName, forKey: AuthStorageKeys.displayName)
        defaults.set(authEmail, forKey: AuthStorageKeys.email)
        defaults.set(backendUserID, forKey: AuthStorageKeys.backendUserID)
        defaults.set(backendRole, forKey: AuthStorageKeys.backendRole)
        defaults.set(hasCompletedInitialAuthChoice, forKey: AuthStorageKeys.initialChoiceCompleted)
    }

    func completeInitialAuthChoiceAsGuest() {
        APIClient.shared.accessToken = nil
        WebSocketInboxClient.shared.stop()

        authMode = .guest
        authUserID = nil
        authDisplayName = nil
        authEmail = nil
        backendUserID = nil
        backendRole = nil
        hasCompletedInitialAuthChoice = true
        persistAuthState()
    }

    func markAppleSignInStarted() {
        appleSignInRequestCounter += 1
        let counter = appleSignInRequestCounter
        isAppleSignInInProgress = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self else { return }
            guard self.appleSignInRequestCounter == counter else { return }
            self.isAppleSignInInProgress = false
        }
    }

    func resetAppleSignInProgress() {
        appleSignInRequestCounter += 1
        isAppleSignInInProgress = false
        appleSignInRawNonce = nil
    }

    func configureAppleLoginRequest(_ request: ASAuthorizationAppleIDRequest) {
        markAppleSignInStarted()
        request.requestedScopes = [.fullName, .email]
        let raw = AppleSignInNonce.randomNonceString()
        appleSignInRawNonce = raw
        request.nonce = AppleSignInNonce.sha256(raw)
    }

    func completeAppleSignIn(with credential: ASAuthorizationAppleIDCredential) {
        let previousUserID = authUserID
        authMode = .apple
        authUserID = credential.user

        if previousUserID != credential.user {
            authEmail = nil
            authDisplayName = nil
        }

        if let email = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            authEmail = email
        }

        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                authDisplayName = name
            }
        }

        if (authDisplayName ?? "").isEmpty {
            authDisplayName = authEmail ?? "DailySpeak User"
        }

        hasCompletedInitialAuthChoice = true
        persistAuthState()
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
        do {
            let response = try await AuthService.shared.refresh()
            applyBackendAuthResponse(response, desiredMode: .email, appleUserID: nil)
        } catch {
            authMode = .email
            authUserID = nil
            authDisplayName = email
            authEmail = email
            hasCompletedInitialAuthChoice = true
            persistAuthState()
            WebSocketInboxClient.shared.startIfPossible()
            PushNotificationService.shared.syncDeviceRegistrationIfPossible()
        }
    }

    @MainActor
    func signOut() {
        if !((APIClient.shared.accessToken ?? "").isEmpty) {
            Task { await AuthService.shared.logout() }
        }
        completeInitialAuthChoiceAsGuest()
    }

    @MainActor
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async -> AppleSignInOutcome {
        defer {
            isAppleSignInInProgress = false
            appleSignInRawNonce = nil
        }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return .failure(message: String(localized: "Apple Sign In capability not configured properly."))
            }

            completeAppleSignIn(with: credential)

            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !idToken.isEmpty,
                  let rawNonce = appleSignInRawNonce?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawNonce.isEmpty else {
                signOut()
                return .failure(message: String(localized: "Apple Sign In returned invalid data, please try again."))
            }

            let fullName: String? = {
                guard let name = credential.fullName else { return nil }
                let formatter = PersonNameComponentsFormatter()
                let value = formatter.string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? nil : value
            }()

            do {
                let response = try await AuthService.shared.oauthApple(
                    idToken: idToken,
                    rawNonce: rawNonce,
                    appleUserID: credential.user,
                    email: credential.email,
                    name: fullName
                )
                applyBackendAuthResponse(response, desiredMode: .apple, appleUserID: credential.user)
                refreshAppleCredentialStateIfNeeded()
                return .success
            } catch let APIError.api(_, message) {
                signOut()
                return .failure(message: message ?? String(localized: "Apple Sign In failed, please try again later."))
            } catch {
                signOut()
                return .failure(message: String(localized: "Apple Sign In failed, please try again later."))
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return .cancelled
            }
            return .failure(message: friendlyAppleSignInMessage(for: error))
        }
    }

    func refreshAppleCredentialStateIfNeeded() {
        guard authMode == .apple else { return }
        guard let authUserID, !authUserID.isEmpty else {
            signOut()
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: authUserID)
                if state == .authorized {
                    if (self.authDisplayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.authDisplayName = self.authEmail ?? "DailySpeak User"
                        self.persistAuthState()
                    }
                } else if state == .revoked || state == .notFound || state == .transferred {
                    self.signOut()
                }
            } catch {
                // Leave current session untouched if Apple cannot be queried.
            }
        }
    }

    @MainActor
    private func applyBackendAuthResponse(_ response: AuthResponseDTO, desiredMode: AuthMode, appleUserID: String?) {
        let accessToken = (response.accessToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !accessToken.isEmpty {
            APIClient.shared.accessToken = accessToken
        }

        backendUserID = response.id
        backendRole = response.role

        authMode = desiredMode
        authUserID = desiredMode == .apple ? appleUserID : nil
        if let email = response.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            authEmail = email
        }
        if let name = response.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            authDisplayName = name
        }
        if (authDisplayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authDisplayName = authEmail ?? "DailySpeak User"
        }
        hasCompletedInitialAuthChoice = true
        persistAuthState()

        WebSocketInboxClient.shared.startIfPossible()
        PushNotificationService.shared.syncDeviceRegistrationIfPossible()
    }

    private func friendlyAppleSignInMessage(for error: Error) -> String {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .failed:
                return String(localized: "Apple Sign In failed, please try again later.")
            case .invalidResponse:
                return String(localized: "Apple Sign In returned invalid data, please try again.")
            case .notHandled, .notInteractive:
                return String(localized: "This device cannot complete Apple Sign In at this time.")
            case .matchedExcludedCredential,
                 .credentialImport,
                 .credentialExport,
                 .preferSignInWithApple,
                 .deviceNotConfiguredForPasskeyCreation,
                 .unknown:
                return String(localized: "Apple Sign In capability not configured properly.")
            case .canceled:
                return String(localized: "You cancelled Apple Sign In.")
            @unknown default:
                return String(localized: "Apple Sign In failed, please try again later.")
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return String(localized: "Network error, unable to connect to Apple Sign In service.")
        }

        return String(localized: "Apple Sign In failed, please try again later.")
    }
}
