import SwiftUI

struct PersonalCenterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(ProgressManager.self) private var progress

    private let dividerInset: CGFloat = 52

    private var totalCompleted: Int {
        CourseData.stages.reduce(0) { partial, stage in
            partial + progress.completedTaskCount(for: stage)
        }
    }

    private var totalTasks: Int {
        CourseData.stages.reduce(0) { $0 + $1.taskCount }
    }

    private var completedStages: Int {
        CourseData.stages.filter { progress.completedTaskCount(for: $0) == $0.taskCount }.count
    }

    private var headerDisplayName: String? {
        let trimmed = appState.authDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        if appState.isLoggedIn, let email = appState.authEmail, !email.isEmpty {
            return email
        }
        return nil
    }

    private var headerSubtitle: String {
        if appState.isLoggedIn {
            return appState.authEmail ?? "已连接 DailySpeak 账号"
        }
        return "游客模式，本地学习进度仍会保留"
    }

    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ZStack(alignment: .topTrailing) {
                        ProfileHeaderCard(
                            displayName: headerDisplayName,
                            subtitle: headerSubtitle,
                            primaryStatTitle: "已完成任务",
                            primaryStatValue: "\(totalCompleted)",
                            secondaryStatTitle: "通关阶段",
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

                    if !appState.isLoggedIn {
                        guestAuthPromptCard
                            .staggeredEntrance(index: 1)
                    }

                    accountCard
                        .staggeredEntrance(index: 2)

                    shortcutCard
                        .staggeredEntrance(index: 3)

                    learningStatsCard
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

    private var guestAuthPromptCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("登录后可以同步账号、接收后端消息和恢复设备推送配置。")
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

    private var accountCard: some View {
        SettingsCard {
            VStack(spacing: 0) {
                ActionMenuRow(
                    icon: appState.isLoggedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle",
                    title: appState.isLoggedIn ? "当前账号" : "当前身份",
                    subtitle: appState.isLoggedIn ? (appState.authEmail ?? appState.authMode.rawValue.capitalized) : "游客模式",
                    iconColor: .primaryCyan
                )

                Divider()
                    .padding(.leading, dividerInset)

                ActionMenuRow(
                    icon: "server.rack",
                    title: "后端用户",
                    subtitle: appState.backendUserID ?? "尚未绑定",
                    iconColor: .info
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
                            subtitle: "退出后回到游客模式",
                            isDestructive: true
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var shortcutCard: some View {
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

                NavigationLink {
                    PaywallPlaceholderView()
                } label: {
                    NavigationMenuRow(
                        icon: "crown.fill",
                        title: "会员中心",
                        subtitle: "先保留入口和页面壳",
                        iconColor: .primaryAmber
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, dividerInset)

                NavigationLink {
                    AppSettingsView()
                        .environmentObject(appState)
                } label: {
                    NavigationMenuRow(
                        icon: "gearshape.fill",
                        title: "设置",
                        subtitle: "通知、反馈、评分和法律信息",
                        iconColor: .info
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

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
