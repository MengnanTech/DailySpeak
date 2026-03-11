import Foundation
import Combine

extension AppState {
    func observeInboxUpdates() {
        inboxObserver = NotificationCenter.default.publisher(for: .pushInboxDidUpdate)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshUnreadCounts()
            }
        refreshUnreadCounts()
    }

    func markNotificationsAsRead() {
        unreadNotificationCount = 0
    }

    func refreshUnreadCounts() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let count = await PushInboxStore.shared.unreadCount()
            unreadNotificationCount = count
            unreadAllMessageCount = count
        }
    }
}
