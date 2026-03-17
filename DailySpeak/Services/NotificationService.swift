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
            return String(localized: "DailySpeak Reminder")
        case .gentle:
            return String(localized: "Save 10 minutes for today's English")
        case .streak:
            return String(localized: "Don't break the streak today")
        }
    }

    var notificationBody: String {
        switch self {
        case .focused:
            return String(localized: "Complete today's speaking practice in 10 minutes.")
        case .gentle:
            return String(localized: "Start a short practice now, tomorrow will be much easier.")
        case .streak:
            return String(localized: "Continue today's practice and keep the streak going.")
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
