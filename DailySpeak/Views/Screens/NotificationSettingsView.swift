import SwiftUI
import UserNotifications
import UIKit

struct NotificationSettingsView: View {
    @AppStorage("dailyspeak.notifications.dailyReminder.enabled") private var dailyReminderEnabled = false
    @AppStorage("dailyspeak.notifications.dailyReminder.hour") private var dailyReminderHour = 20
    @AppStorage("dailyspeak.notifications.dailyReminder.minute") private var dailyReminderMinute = 30

    @State private var permissionStatus: UNAuthorizationStatus?
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        Form {
            Section {
                Toggle("Daily reminder", isOn: $dailyReminderEnabled)
                    .onChange(of: dailyReminderEnabled) { _, newValue in
                        if newValue {
                            Task { await enableDailyReminder() }
                        } else {
                            NotificationService.shared.cancelDailyReminder()
                        }
                    }

                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: [.hourAndMinute]
                )
                .disabled(!dailyReminderEnabled)
            } footer: {
                Text("DailySpeak only requests notification permission when you turn reminders on.")
            }

            Section {
                HStack {
                    Text("Permission")
                    Spacer()
                    Text(permissionLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshPermissionStatus()
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") {
                openSystemSettings()
            }
        } message: {
            Text("Enable notification permission in Settings to receive DailySpeak reminders.")
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: dailyReminderHour,
                    minute: dailyReminderMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                dailyReminderHour = components.hour ?? dailyReminderHour
                dailyReminderMinute = components.minute ?? dailyReminderMinute
                if dailyReminderEnabled {
                    NotificationService.shared.scheduleDailyReminder(at: newValue)
                }
            }
        )
    }

    private var permissionLabel: String {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return "On"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Asked"
        case .none:
            return "Loading"
        @unknown default:
            return "Unknown"
        }
    }

    private func refreshPermissionStatus() async {
        permissionStatus = await NotificationService.shared.checkPermissionStatus()
    }

    private func enableDailyReminder() async {
        let status = await NotificationService.shared.checkPermissionStatus()
        permissionStatus = status

        if status == .denied {
            dailyReminderEnabled = false
            showPermissionDeniedAlert = true
            return
        }

        if status == .notDetermined {
            let granted = await NotificationService.shared.requestPermission()
            await refreshPermissionStatus()
            if !granted {
                dailyReminderEnabled = false
                showPermissionDeniedAlert = true
                return
            }
        }

        NotificationService.shared.scheduleDailyReminder(at: reminderTimeBinding.wrappedValue)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
