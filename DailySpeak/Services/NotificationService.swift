import Foundation
import UserNotifications

enum ReminderTone: String, CaseIterable, Identifiable {
    case focused
    case gentle
    case streak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focused:
            return "Focused"
        case .gentle:
            return "Gentle"
        case .streak:
            return "Streak"
        }
    }

    var notificationTitle: String {
        switch self {
        case .focused:
            return "DailySpeak 提醒"
        case .gentle:
            return "留 10 分钟给今天的英语"
        case .streak:
            return "别让 streak 断在今天"
        }
    }

    var notificationBody: String {
        switch self {
        case .focused:
            return "用 10 分钟完成今天的一次口语练习。"
        case .gentle:
            return "现在开始一小段练习，明天会轻松很多。"
        case .streak:
            return "继续今天的一次练习，把连续学习保持下去。"
        }
    }
}

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

    func scheduleDailyReminder(at time: Date, tone: ReminderTone = .focused) {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = tone.notificationTitle
        content.body = tone.notificationBody
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
