import Foundation
import UserNotifications

final class UserNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = UserNotificationDelegate()

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.trigger is UNPushNotificationTrigger {
            var userInfo = notification.request.content.userInfo
            userInfo["_apns_dedupe_id"] = notification.request.identifier
            PushNotificationService.shared.handleRemoteNotification(userInfo: userInfo)
        }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.trigger is UNPushNotificationTrigger {
            var userInfo = response.notification.request.content.userInfo
            userInfo["_apns_dedupe_id"] = response.notification.request.identifier
            PushNotificationService.shared.handleRemoteNotification(userInfo: userInfo)
            Task { @MainActor in
                InboxNavigationCoordinator.shared.openInbox()
            }
        }
        completionHandler()
    }
}
