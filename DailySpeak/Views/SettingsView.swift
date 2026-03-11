import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProgressManager.self) private var progress
    @Environment(\.openURL) private var openURL

    @State private var showNotifications = false

    var body: some View {
        List {
            Section("Account") {
                Text(appState.isLoggedIn ? (appState.authEmail ?? appState.authDisplayName ?? "Signed in") : "Guest mode")

                if appState.isLoggedIn {
                    Button("Sign Out", role: .destructive) {
                        appState.signOut()
                    }
                }
            }

            Section("Preferences") {
                Button("Daily Reminder") {
                    showNotifications = true
                }

                Button("Rate DailySpeak") {
                    ReviewPromptService.shared.requestReviewIfAppropriate()
                }

                Button("Reset Local Progress", role: .destructive) {
                    progress.resetAll()
                }
            }

            Section("Support") {
                Button("Send Feedback") {
                    let payload = FeedbackService.buildPayload(appState: appState)
                    if let url = FeedbackService.mailtoURL(subject: payload.subject, body: payload.body) {
                        openURL(url)
                    }
                }

                if let url = URL(string: Constants.privacyPolicyURL) {
                    Link("Privacy Policy", destination: url)
                }
                if let url = URL(string: Constants.termsOfServiceURL) {
                    Link("Terms of Service", destination: url)
                }
            }
        }
        .navigationTitle("SettingsView")
        .navigationDestination(isPresented: $showNotifications) {
            NotificationSettingsView()
        }
    }
}
