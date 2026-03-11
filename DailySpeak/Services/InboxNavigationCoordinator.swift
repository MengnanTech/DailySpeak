import Foundation
import Combine

@MainActor
final class InboxNavigationCoordinator: ObservableObject {
    static let shared = InboxNavigationCoordinator()

    @Published var shouldPresentInbox = false

    private init() {}

    func openInbox() {
        shouldPresentInbox = true
    }
}
