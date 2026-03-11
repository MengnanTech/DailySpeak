import Foundation
import Observation

@Observable
final class AppState {
    static var currentAuthModeRawValue = AuthMode.guest.rawValue

    enum AuthMode: String {
        case guest
        case apple
        case email
    }

    enum AppleSignInOutcome: Equatable {
        case success
        case cancelled
        case failure(message: String)
    }

    var authMode: AuthMode = .guest
    var authUserID: String?
    var authDisplayName: String?
    var authEmail: String?
    var backendUserID: String?
    var backendRole: String?
    var isAppleSignInInProgress = false
    var hasCompletedOnboarding = false
    var hasCompletedInitialAuthChoice = false

    var shouldShowOnboarding: Bool { !hasCompletedOnboarding }
    var shouldShowAuthChoice: Bool { hasCompletedOnboarding && !hasCompletedInitialAuthChoice }
    var isLoggedIn: Bool {
        authMode != .guest && ((APIClient.shared.accessToken ?? "").isEmpty == false)
    }

    init() {
        loadAuthState()
    }
}
