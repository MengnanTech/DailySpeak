import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(ProgressManager.self) private var progress
    @Environment(\.openURL) private var openURL

    @State private var showResetAlert = false
    @State private var showFeedbackFallbackAlert = false

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Text("Mode")
                    Spacer()
                    Text(appState.authMode.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }

                if let email = appState.authEmail, !email.isEmpty {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Preferences") {
                NavigationLink("Notification Settings") {
                    NotificationSettingsView()
                }

                NavigationLink("Premium Placeholder") {
                    PaywallPlaceholderView()
                }
            }

            Section("Support") {
                Button("Send Feedback") {
                    sendFeedback()
                }

                Button("Rate DailySpeak") {
                    ReviewPromptService.shared.requestReviewManually()
                }
            }

            Section("Legal") {
                if let privacy = URL(string: Constants.privacyPolicyURL) {
                    Link("Privacy Policy", destination: privacy)
                }
                if let terms = URL(string: Constants.termsOfServiceURL) {
                    Link("Terms of Service", destination: terms)
                }
            }

            Section("Learning Data") {
                Button("Reset Local Progress", role: .destructive) {
                    showResetAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset local progress?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                progress.resetAll()
            }
        } message: {
            Text("This clears completed task and step state stored on this device.")
        }
        .alert("Unable to open mail", isPresented: $showFeedbackFallbackAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No email app is available for feedback.")
        }
    }

    private func sendFeedback() {
        let payload = FeedbackService.buildPayload(appState: appState)
        guard let recipient = payload.recipients.first,
              let url = FeedbackService.mailtoURL(to: recipient, subject: payload.subject, body: payload.body) else {
            showFeedbackFallbackAlert = true
            return
        }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
            .environmentObject(AppState())
            .environment(ProgressManager())
    }
}
