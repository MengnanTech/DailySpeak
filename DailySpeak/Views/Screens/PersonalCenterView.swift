import SwiftUI

struct PersonalCenterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(ProgressManager.self) private var progress

    private let dividerInset: CGFloat = 52
    private let gold = Color(hex: "C89B3C")
    private let goldLight = Color(hex: "DCBC6A")

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
            Color.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Profile Header
                    ZStack(alignment: .topTrailing) {
                        ProfileHeaderCard(
                            displayName: headerDisplayName,
                            subtitle: headerSubtitle,
                            primaryStatTitle: "已完成任务",
                            primaryStatValue: "\(totalCompleted)",
                            secondaryStatTitle: "已完成阶段",
                            secondaryStatValue: "\(completedStages)",
                            themeColor: .primaryCyan,
                            showsVIPCrown: false
                        )

                        NavigationLink {
                            AppSettingsView()
                                .environmentObject(appState)
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color.backgroundSecondary.opacity(0.9))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                        .accessibilityLabel(Text("设置"))
                    }
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

                    // Quick Actions
                    actionsCard
                        .staggeredEntrance(index: 4)
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
    }

    // MARK: - PRO Banner
    private var proBanner: some View {
        NavigationLink {
            PaywallPlaceholderView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 46, height: 46)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("升级到 DailySpeak PRO")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("解锁全部 \(CourseData.stages.count) 个阶段和 \(proTaskCount)+ 口语课程")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
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
                    .foregroundColor(.textSecondary)

                HStack(spacing: 10) {
                    NavigationLink {
                        AuthLoginRegisterView(initialMode: .login)
                            .environmentObject(appState)
                    } label: {
                        Text("登录")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.backgroundSecondary)
                            )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AuthLoginRegisterView(initialMode: .register)
                            .environmentObject(appState)
                    } label: {
                        Text("注册")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textMuted.opacity(0.45), lineWidth: 1)
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
                Text("学习概览")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

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

    // MARK: - Actions Card
    private var actionsCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                NavigationLink {
                    NotificationsView()
                        .environmentObject(appState)
                } label: {
                    NavigationMenuRow(
                        icon: "bell.fill",
                        title: "消息通知",
                        subtitle: unreadSubtitle,
                        iconColor: .primaryCyan
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, dividerInset)

                ActionMenuRow(
                    icon: appState.isLoggedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle",
                    title: appState.isLoggedIn ? "当前账号" : "当前身份",
                    subtitle: appState.isLoggedIn ? (appState.authEmail ?? appState.authMode.rawValue.capitalized) : "游客模式",
                    iconColor: .primaryCyan
                )

                if appState.isLoggedIn {
                    Divider()
                        .padding(.leading, dividerInset)

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

    // MARK: - Helpers
    private var unreadSubtitle: String {
        let unread = appState.unreadNotificationCount
        return unread == 0 ? "目前没有未读消息" : "还有 \(unread) 条未读消息"
    }

    private func metricView(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary.opacity(0.6))
        )
    }

    private func stageProgressRow(for stage: Stage) -> some View {
        let completed = progress.completedTaskCount(for: stage)
        let progressValue = progress.stageProgress(for: stage)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Stage \(stage.id) · \(stage.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(completed)/\(stage.taskCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.backgroundSecondary)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geometry.size.width * progressValue)
                }
            }
            .frame(height: 10)
        }
    }
}

#Preview {
    NavigationStack {
        PersonalCenterView()
            .environmentObject(AppState())
            .environment(ProgressManager())
    }
}
