import SwiftUI

struct PersonalCenterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(ProgressManager.self) private var progress
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL

    private let dividerInset: CGFloat = 52
    private let gold = Color(hex: "C89B3C")
    private let goldLight = Color(hex: "DCBC6A")

    @State private var showResetAlert = false
    @State private var showFeedbackFallbackAlert = false
    @State private var showOnboarding = false
    @State private var showPaywall = false

    private var totalCompleted: Int {
        CourseData.stages.reduce(0) { $0 + progress.completedTaskCount(for: $1) }
    }

    private var totalTasks: Int {
        CourseData.stages.reduce(0) { $0 + $1.taskCount }
    }

    private var completedStages: Int {
        CourseData.stages.filter { progress.completedTaskCount(for: $0) == $0.taskCount }.count
    }

    private var headerDisplayName: String? {
        let trimmed = appState.authDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        if appState.isLoggedIn, let email = appState.authEmail, !email.isEmpty { return email }
        return nil
    }

    private var headerSubtitle: String {
        "持续练习，提升口语表达能力"
    }

    private var proTaskCount: Int {
        CourseData.stages.dropFirst().reduce(0) { $0 + $1.taskCount }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Profile Header
                    ProfileHeaderCard(
                        displayName: headerDisplayName,
                        subtitle: headerSubtitle,
                        primaryStatTitle: "已完成任务",
                        primaryStatValue: "\(totalCompleted)",
                        secondaryStatTitle: "已完成阶段",
                        secondaryStatValue: "\(completedStages)",
                        themeColor: Color(hex: "4F6BED"),
                        showsVIPCrown: subscription.isPro
                    )
                    .padding(.top, 8)
                    .staggeredEntrance(index: 0)

                    // PRO Banner
                    proBanner
                        .staggeredEntrance(index: 1)

                    // Login Prompt
                    if !appState.isLoggedIn {
                        loginPromptCard
                            .staggeredEntrance(index: 2)
                    }

                    // Learning Stats
                    learningStatsCard
                        .staggeredEntrance(index: 3)

                    // Preferences (Voice, Notifications, Premium)
                    preferencesSection
                        .staggeredEntrance(index: 4)

                    // Quick Actions (Messages, Account, Logout)
                    actionsCard
                        .staggeredEntrance(index: 5)

                    // Support (Guide, Feedback, Rate)
                    supportSection
                        .staggeredEntrance(index: 6)

                    // Legal + Danger
                    legalAndDangerSection
                        .staggeredEntrance(index: 7)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appState.refreshAppleCredentialStateIfNeeded()
        }
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

    // MARK: - PRO Banner
    private var proBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 46, height: 46)

                    Image(systemName: subscription.isPro ? "checkmark.seal.fill" : "crown.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.isPro ? "DailySpeak PRO" : "升级到 DailySpeak PRO")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subscription.isPro
                         ? "已解锁全部高级内容"
                         : "解锁全部 \(CourseData.stages.count) 个阶段和 \(proTaskCount)+ 口语课程")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 0)

                if !subscription.isPro {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(18)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [gold, goldLight, gold.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RadialGradient(
                        colors: [.white.opacity(0.12), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: gold.opacity(0.3), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Login Prompt
    private var loginPromptCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("登录后可同步学习进度、接收消息通知和解锁更多功能。")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)

                HStack(spacing: 10) {
                    NavigationLink {
                        AuthLoginRegisterView(initialMode: .login)
                            .environmentObject(appState)
                    } label: {
                        Text("登录")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.surface)
                            )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AuthLoginRegisterView(initialMode: .register)
                            .environmentObject(appState)
                    } label: {
                        Text("注册")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Learning Stats
    private var learningStatsCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(title: "学习概览", icon: "chart.bar.fill", color: Color(hex: "4F6BED"))

                HStack(spacing: 12) {
                    metricView(value: "\(totalCompleted)", label: "已完成")
                    metricView(value: "\(max(totalTasks - totalCompleted, 0))", label: "未完成")
                    metricView(value: "\(CourseData.stages.count)", label: "总阶段")
                }
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    ForEach(CourseData.stages, id: \.id) { stage in
                        stageProgressRow(for: stage)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Preferences
    private var preferencesSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "偏好设置", icon: "slider.horizontal.3", color: Color(hex: "8B5CF6"))

                NavigationLink {
                    VoiceSettingsView()
                } label: {
                    NavigationMenuRow(
                        icon: "waveform.circle.fill",
                        title: "语音选择",
                        subtitle: VoiceManager.shared.selectedVoice.name,
                        iconColor: Color(hex: "4F6BED")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, dividerInset)

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    NavigationMenuRow(
                        icon: "bell.badge.fill",
                        title: "通知设置",
                        subtitle: "提醒和通知",
                        iconColor: Color(hex: "10B981")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions Card
    private var actionsCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "账号", icon: "person.circle.fill", color: Color(hex: "4A90D9"))

                NavigationLink {
                    NotificationsView()
                        .environmentObject(appState)
                } label: {
                    NavigationMenuRow(
                        icon: "bell.fill",
                        title: "消息通知",
                        subtitle: unreadSubtitle,
                        iconColor: Color(hex: "4A90D9")
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, dividerInset)

                ActionMenuRow(
                    icon: appState.isLoggedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle",
                    title: appState.isLoggedIn ? "当前账号" : "当前身份",
                    subtitle: appState.isLoggedIn ? (appState.authEmail ?? appState.authMode.rawValue.capitalized) : "游客模式",
                    iconColor: .primaryCyan
                )

                if appState.isLoggedIn {
                    Divider().padding(.leading, dividerInset)

                    Button {
                        appState.signOut()
                    } label: {
                        ActionMenuRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "退出登录",
                            subtitle: "退出后将清除登录状态",
                            isDestructive: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Support
    private var supportSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "支持", icon: "questionmark.circle.fill", color: Color(hex: "4A90D9"))

                Button { showOnboarding = true } label: {
                    NavigationMenuRow(
                        icon: "hand.wave.fill",
                        title: "新手引导",
                        subtitle: "重新查看使用教程",
                        iconColor: Color(hex: "8B5CF6")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, dividerInset)

                Button { sendFeedback() } label: {
                    NavigationMenuRow(
                        icon: "envelope.open.fill",
                        title: "意见反馈",
                        subtitle: "帮助我们改进 DailySpeak",
                        iconColor: Color(hex: "4A90D9")
                    )
                }
                .buttonStyle(.plain)

                Divider().background(AppColors.border).padding(.leading, dividerInset)

                Button {
                    ReviewPromptService.shared.requestReviewManually()
                } label: {
                    NavigationMenuRow(
                        icon: "star.fill",
                        title: "给个好评",
                        subtitle: "在 App Store 上评价",
                        iconColor: Color(hex: "F59E0B")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Legal + Danger
    private var legalAndDangerSection: some View {
        SettingsCard {
            VStack(spacing: 0) {
                sectionHeader(title: "其他", icon: "ellipsis.circle.fill", color: AppColors.tertiaryText)

                if let privacy = URL(string: Constants.privacyPolicyURL) {
                    Link(destination: privacy) {
                        NavigationMenuRow(
                            icon: "hand.raised.fill",
                            title: "隐私政策",
                            subtitle: nil,
                            iconColor: Color(hex: "10B981")
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(AppColors.border).padding(.leading, dividerInset)

                if let terms = URL(string: Constants.termsOfServiceURL) {
                    Link(destination: terms) {
                        NavigationMenuRow(
                            icon: "doc.plaintext.fill",
                            title: "用户协议",
                            subtitle: nil,
                            iconColor: AppColors.tertiaryText
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(AppColors.border).padding(.leading, dividerInset)

                Button {
                    showResetAlert = true
                } label: {
                    ActionMenuRow(
                        icon: "trash.fill",
                        title: "重置学习进度",
                        subtitle: "清除所有已完成的任务和步骤",
                        isDestructive: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers
    private var unreadSubtitle: String {
        let unread = appState.unreadNotificationCount
        return unread == 0 ? "目前没有未读消息" : "还有 \(unread) 条未读消息"
    }

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

    private func metricView(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppColors.secondText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface.opacity(0.6))
        )
    }

    private func stageProgressRow(for stage: Stage) -> some View {
        let completed = progress.completedTaskCount(for: stage)
        let progressValue = progress.stageProgress(for: stage)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Stage \(stage.id) · \(stage.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text("\(completed)/\(stage.taskCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(AppColors.surface)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(stage.theme.gradient)
                        .frame(width: geometry.size.width * progressValue)
                }
            }
            .frame(height: 10)
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
        PersonalCenterView()
            .environmentObject(AppState())
            .environment(ProgressManager())
            .environment(SubscriptionManager())
    }
}
