import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(ProgressManager.self) private var progress
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL

    @State private var showResetAlert = false
    @State private var showFeedbackFallbackAlert = false
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @AppStorage(DailySpeakAPIService.translationProviderKey) private var translationProvider = "auto"

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    accountSection
                        .staggeredEntrance(index: 0)

                    preferencesSection
                        .staggeredEntrance(index: 1)

                    supportSection
                        .staggeredEntrance(index: 2)

                    legalSection
                        .staggeredEntrance(index: 3)

                    dangerSection
                        .staggeredEntrance(index: 4)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
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
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallPlaceholderView()
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "Account", icon: "person.circle.fill", color: Color(hex: "4F6BED"))

                ActionMenuRow(
                    icon: "person.fill",
                    title: "Mode",
                    subtitle: appState.authMode.rawValue.capitalized,
                    iconColor: Color(hex: "4F6BED")
                )

                if let email = appState.authEmail, !email.isEmpty {
                    Divider().background(AppColors.border).padding(.leading, 64)

                    ActionMenuRow(
                        icon: "envelope.fill",
                        title: "Email",
                        subtitle: email,
                        iconColor: Color(hex: "4A90D9")
                    )
                }
            }
        }
    }

    // MARK: - Preferences
    private var preferencesSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "Preferences", icon: "slider.horizontal.3", color: Color(hex: "8B5CF6"))

                NavigationLink {
                    VoiceSettingsView()
                } label: {
                    NavigationMenuRow(
                        icon: "waveform.circle.fill",
                        title: "Voice Selection",
                        subtitle: VoiceManager.shared.selectedVoice.name,
                        iconColor: Color(hex: "4F6BED")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, 64)

                translationProviderRow

                Divider().background(AppColors.border).padding(.leading, 64)

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    NavigationMenuRow(
                        icon: "bell.badge.fill",
                        title: "Notification Settings",
                        subtitle: "Reminders and alerts",
                        iconColor: Color(hex: "10B981")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, 64)

                Button { showPaywall = true } label: {
                    NavigationMenuRow(
                        icon: subscription.isPro ? "checkmark.seal.fill" : "crown.fill",
                        title: "Premium",
                        subtitle: subscription.isPro ? "PRO Active" : "Unlock advanced features",
                        iconColor: Color(hex: "C89B3C")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Support
    private var supportSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "Support", icon: "questionmark.circle.fill", color: Color(hex: "4A90D9"))

                Button { showOnboarding = true } label: {
                    NavigationMenuRow(
                        icon: "hand.wave.fill",
                        title: "New User Guide",
                        subtitle: "Review the onboarding tutorial",
                        iconColor: Color(hex: "8B5CF6")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, 64)

                Button { sendFeedback() } label: {
                    NavigationMenuRow(
                        icon: "envelope.open.fill",
                        title: "Send Feedback",
                        subtitle: "Help us improve DailySpeak",
                        iconColor: Color(hex: "4A90D9")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, 64)

                Button {
                    ReviewPromptService.shared.requestReviewManually()
                } label: {
                    NavigationMenuRow(
                        icon: "star.fill",
                        title: "Rate DailySpeak",
                        subtitle: "Leave a review on the App Store",
                        iconColor: Color(hex: "F59E0B")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "Legal", icon: "doc.text.fill", color: AppColors.secondText)

                if let privacy = URL(string: Constants.privacyPolicyURL) {
                    Link(destination: privacy) {
                        NavigationMenuRow(
                            icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            subtitle: nil,
                            iconColor: Color(hex: "10B981")
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(AppColors.border).padding(.leading, 64)

                if let terms = URL(string: Constants.termsOfServiceURL) {
                    Link(destination: terms) {
                        NavigationMenuRow(
                            icon: "doc.plaintext.fill",
                            title: "Terms of Service",
                            subtitle: nil,
                            iconColor: AppColors.secondText
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Danger Zone
    private var dangerSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                Button {
                    showResetAlert = true
                } label: {
                    ActionMenuRow(
                        icon: "trash.fill",
                        title: "Reset Local Progress",
                        subtitle: "Clear all completed tasks and steps",
                        isDestructive: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Translation Provider
    private var translationProviderRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color(hex: "0EA5E9"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Translation Engine")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                Text(translationProviderLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Spacer()

            Menu {
                Button { translationProvider = "auto" } label: {
                    Label("Auto (DeepL)", systemImage: translationProvider == "auto" ? "checkmark" : "")
                }
                Button { translationProvider = "deepl" } label: {
                    Label("DeepL", systemImage: translationProvider == "deepl" ? "checkmark" : "")
                }
                Button { translationProvider = "deepseek" } label: {
                    Label("DeepSeek AI", systemImage: translationProvider == "deepseek" ? "checkmark" : "")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(translationProviderLabel)
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "0EA5E9"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "0EA5E9").opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var translationProviderLabel: String {
        switch translationProvider {
        case "deepl": "DeepL"
        case "deepseek": "DeepSeek AI"
        default: "Auto"
        }
    }

    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColors.tertiaryText)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
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
            .environment(SubscriptionManager())
    }
}
