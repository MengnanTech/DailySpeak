import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage(Constants.StorageKeys.notificationsEnabled) private var isEnabled = false
    @AppStorage(Constants.StorageKeys.notificationsHour) private var hour = 20
    @AppStorage(Constants.StorageKeys.notificationsMinute) private var minute = 0

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showDeniedAlert = false

    var body: some View {
        Form {
            Toggle("Daily Reminder", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    Task {
                        await updateToggle(newValue)
                    }
                }
            ))

            if isEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: { reminderDate },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            hour = components.hour ?? 20
                            minute = components.minute ?? 0
                            NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            Text("Permission: \(statusText)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("NotificationSettingsView")
        .task {
            permissionStatus = await NotificationService.shared.checkPermissionStatus()
        }
        .alert("Notifications Disabled", isPresented: $showDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive daily reminders.")
        }
    }

    private var reminderDate: Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }

    private var statusText: String {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return "On"
        case .denied:
            return "Denied"
        default:
            return "Off"
        }
    }

    private func updateToggle(_ newValue: Bool) async {
        if newValue {
            let granted = await NotificationService.shared.requestPermission()
            permissionStatus = await NotificationService.shared.checkPermissionStatus()
            if granted {
                isEnabled = true
                NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
            } else {
                isEnabled = false
                showDeniedAlert = true
            }
        } else {
            isEnabled = false
            NotificationService.shared.cancelDailyReminder()
        }
    }
}
