import SwiftUI
import Combine

enum AppTab: String, Hashable {
    case home
    case messages
    case me
}

@MainActor
final class AppState: ObservableObject {
    enum AuthMode: String, Equatable {
        case guest
        case apple
        case email
    }

    enum AppleSignInOutcome: Equatable {
        case success
        case cancelled
        case failure(message: String)
    }

    @Published var selectedTab: AppTab = .home
    @Published var authMode: AuthMode = .guest
    @Published var authUserID: String?
    @Published var authDisplayName: String?
    @Published var authEmail: String?
    @Published var backendUserID: String?
    @Published var backendRole: String?
    @Published var unreadNotificationCount = 0
    @Published var unreadAllMessageCount = 0
    @Published var isAppleSignInInProgress = false
    @Published var hasCompletedInitialAuthChoice = false

    var inboxObserver: AnyCancellable?
    var appleSignInRequestCounter = 0
    var appleSignInRawNonce: String?

    init() {
        loadAuthState()
        observeInboxUpdates()
    }

    func startRuntimeServices() {
        refreshAppleCredentialStateIfNeeded()
        WebSocketInboxClient.shared.startIfPossible()
        PushNotificationService.shared.syncDeviceRegistrationIfPossible()
        Task { await InAppInboxService.shared.syncIfConfigured() }
    }

    func stopRuntimeServices() {
        WebSocketInboxClient.shared.stop()
    }
}
