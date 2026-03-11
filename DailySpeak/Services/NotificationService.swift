import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyReminder(at time: Date) {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "DailySpeak 提醒"
        content.body = "用 10 分钟完成今天的一次口语练习。"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyspeak.dailyReminder", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyspeak.dailyReminder"])
    }
}
