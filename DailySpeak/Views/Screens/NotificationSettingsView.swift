import SwiftUI
import UserNotifications
import UIKit

struct NotificationSettingsView: View {
    @AppStorage("dailyspeak.notifications.dailyReminder.enabled") private var dailyReminderEnabled = false
    @AppStorage("dailyspeak.notifications.dailyReminder.hour") private var dailyReminderHour = 20
    @AppStorage("dailyspeak.notifications.dailyReminder.minute") private var dailyReminderMinute = 30
    @AppStorage("dailyspeak.notifications.dailyReminder.tone") private var dailyReminderToneRawValue = ReminderTone.focused.rawValue

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

            Section("Reminder tone") {
                Picker("Tone", selection: reminderToneBinding) {
                    ForEach(ReminderTone.allCases) { tone in
                        Text(tone.title).tag(tone)
                    }
                }
                .pickerStyle(.segmented)

                reminderPreviewCard
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
        .onChange(of: dailyReminderToneRawValue) { _, _ in
            guard dailyReminderEnabled else { return }
            NotificationService.shared.scheduleDailyReminder(
                at: reminderTimeBinding.wrappedValue,
                tone: selectedReminderTone
            )
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
                    NotificationService.shared.scheduleDailyReminder(at: newValue, tone: selectedReminderTone)
                }
            }
        )
    }

    private var reminderToneBinding: Binding<ReminderTone> {
        Binding(
            get: { selectedReminderTone },
            set: { dailyReminderToneRawValue = $0.rawValue }
        )
    }

    private var selectedReminderTone: ReminderTone {
        ReminderTone(rawValue: dailyReminderToneRawValue) ?? .focused
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
            await MainActor.run {
                PushNotificationService.shared.registerForRemoteNotificationsIfPossible()
            }
        }

        NotificationService.shared.scheduleDailyReminder(
            at: reminderTimeBinding.wrappedValue,
            tone: selectedReminderTone
        )
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var reminderPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(Color(hex: "5B9BF0"))
                Text("Preview")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text(timePreviewText)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Text(selectedReminderTone.notificationTitle)
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)

            Text(selectedReminderTone.notificationBody)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }

    private var timePreviewText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: reminderTimeBinding.wrappedValue)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
