import SwiftUI

struct StageListView: View {
    @Environment(ProgressManager.self) private var progress
    @Environment(SubscriptionManager.self) private var subscription
    let unreadCount: Int
    let onProfileTap: () -> Void
    let onInboxTap: () -> Void
    @State private var selectedStage: Stage?
    @State private var selectedTask: SpeakingTask?
    @State private var carouselStageId: Int?
    @State private var displayedTaskStageId: Int?
    @State private var taskListInsertionEdge: Edge = .trailing
    @State private var taskListStageVisibility: [Int: Bool] = [:]
    @State private var paywallTarget: PaywallTarget? = nil

    private let stages = CourseData.stages

    private var currentStage: Stage {
        stages.first { progress.stageProgress(for: $0) < 1.0 } ?? stages.last!
    }
    private var totalCompleted: Int {
        stages.reduce(0) { $0 + progress.completedTaskCount(for: $1) }
    }
    private var totalTasks: Int {
        stages.reduce(0) { $0 + $1.taskCount }
    }
    private var allCompleted: Bool { totalCompleted >= totalTasks && totalTasks > 0 }

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        statsRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, allCompleted ? 16 : 28)

                        if allCompleted {
                            completionCelebration
                                .padding(.horizontal, 20)
                                .padding(.bottom, 28)
                        }

                        sectionHeader
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                        // Horizontal carousel
                        stageCarousel
                            .padding(.bottom, 14)

                        pageIndicator
                            .padding(.bottom, 32)

                        // Task list for selected stage
                        if let stageId = displayedTaskStageId,
                           let stage = stages.first(where: { $0.id == stageId }) {
                            taskListSection(stage: stage, visible: taskListStageVisibility[stageId] ?? false)
                                .id(stageId)
                                .transition(taskListTransition)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedStage) { stage in
                TaskGridView(stage: stage)
            }
            .navigationDestination(item: $selectedTask) { task in
                let stage = stages.first { s in s.tasks.contains { $0.id == task.id } } ?? currentStage
                TaskLoadingContainerView(stage: stage, task: task)
            }
            .sheet(item: $paywallTarget) { target in
                PaywallPlaceholderView(targetStageId: target.stageId)
            }
            .onAppear {
                if carouselStageId == nil {
                    carouselStageId = currentStage.id
                }
                let targetStageId = carouselStageId ?? currentStage.id
                if displayedTaskStageId == nil {
                    displayedTaskStageId = targetStageId
                }
                animateTaskListEntrance(for: targetStageId, delay: 0.1)
            }
            .onChange(of: carouselStageId) { _, newStageId in
                guard let newStageId else { return }
                guard displayedTaskStageId != newStageId else { return }
                if let oldStageId = displayedTaskStageId {
                    taskListInsertionEdge = newStageId > oldStageId ? .trailing : .leading
                }
                taskListStageVisibility[newStageId] = false
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    displayedTaskStageId = newStageId
                }
                animateTaskListEntrance(for: newStageId, delay: 0.06)
            }
        }
    }

    private func animateTaskListEntrance(for stageId: Int, delay: TimeInterval) {
        taskListStageVisibility[stageId] = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                taskListStageVisibility[stageId] = true
            }
        }
    }

    private var taskListTransition: AnyTransition {
        let removalEdge: Edge = taskListInsertionEdge == .trailing ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: taskListInsertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    // MARK: - Top Header
    private var topHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString())
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
                Text(greetingText())
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            Spacer()
            HStack(spacing: 10) {
                headerIconButton(icon: "person.crop.circle.fill", badgeCount: 0, action: onProfileTap)
                headerIconButton(icon: "bell.fill", badgeCount: unreadCount, action: onInboxTap)
            }
        }
    }

    private func headerIconButton(icon: String, badgeCount: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 42, height: 42)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .cardShadow()

                if badgeCount > 0 {
                    Text("\(min(badgeCount, 99))")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(hex: "E85D4A")))
                        .offset(x: 10, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        let streak = progress.currentStreakDays()
        let todayStudy = ProgressManager.formatStudyTime(seconds: progress.todayStudySeconds())
        return HStack(spacing: 10) {
            StatChip(icon: "flame.fill", iconColor: Color(hex: "F97316"),
                     value: "\(streak)", label: "day streak")
            StatChip(icon: "clock.fill", iconColor: Color(hex: "8B5CF6"),
                     value: todayStudy, label: "today")
            StatChip(icon: "chart.bar.fill", iconColor: Color(hex: "5B9BF0"),
                     value: "\(totalCompleted)/\(totalTasks)", label: "total")
        }
    }

    // MARK: - Section Header
    private var sectionHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Your Journey")
                    .font(.title3.bold()).foregroundStyle(AppColors.primaryText)
                Text("9 stages · \(totalTasks) tasks to fluency")
                    .font(.caption).foregroundStyle(AppColors.tertiaryText)
            }
            Spacer()
        }
    }

    // MARK: - Stage Carousel (Pseudo-3D)
    private var stageCarousel: some View {
        GeometryReader { geo in
            let sidePeek = min(24, max(12, geo.size.width * 0.06))
            let itemSpacing: CGFloat = min(10, max(6, geo.size.width * 0.018))
            let cardWidth = max(0, geo.size.width - sidePeek * 2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: itemSpacing) {
                    ForEach(stages) { stage in
                        CarouselStageCard(
                            stage: stage,
                            onStageTap: {
                                if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                                    paywallTarget = PaywallTarget(stageId: stage.id)
                                    return
                                }
                                guard progress.isStageUnlocked(stageId: stage.id, subscription: subscription) else { return }
                                selectedStage = stage
                            },
                            onTaskTap: { task in
                                if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                                    paywallTarget = PaywallTarget(stageId: stage.id)
                                    return
                                }
                                guard progress.isStageUnlocked(stageId: stage.id, subscription: subscription) else { return }
                                selectedTask = task
                            }
                        )
                        .frame(width: cardWidth)
                        .scrollTransition(.animated(.spring(response: 0.5, dampingFraction: 0.78))) { content, phase in
                            let p = phase.value
                            let absP = min(abs(p), 1.0)
                            return content
                                .opacity(1 - absP * 0.35)
                                .scaleEffect(
                                    x: 1 - absP * 0.08,
                                    y: 1 - absP * 0.12,
                                    anchor: p > 0 ? .leading : .trailing
                                )
                                .rotation3DEffect(
                                    .degrees(-p * 25),
                                    axis: (x: 0.08, y: 1, z: 0.02),
                                    anchor: p > 0 ? .leading : .trailing,
                                    perspective: 0.4
                                )
                                .offset(y: absP * 12)
                                .blur(radius: absP * 1.5)
                        }
                        .id(stage.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 28)
            }
            .contentMargins(.horizontal, sidePeek, for: .scrollContent)
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $carouselStageId, anchor: .center)
        }
        .frame(height: 286)
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(stages) { stage in
                let isActive = stage.id == (carouselStageId ?? currentStage.id)
                RoundedRectangle(cornerRadius: 3)
                    .fill(isActive ? stage.theme.startColor : AppColors.border.opacity(0.9))
                    .frame(width: isActive ? 18 : 5, height: 5)
                    .shadow(
                        color: isActive ? stage.theme.startColor.opacity(0.25) : .clear,
                        radius: isActive ? 6 : 0,
                        x: 0,
                        y: 1
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.76), value: carouselStageId)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.card.opacity(0.88), in: Capsule())
        .overlay(
            Capsule()
                .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Task List Section
    private func visibleTasks(for stage: Stage, maxCount: Int = 4) -> [SpeakingTask] {
        let tasks = stage.tasks
        guard tasks.count > maxCount else { return tasks }
        // Find first uncompleted task
        if let nextIndex = tasks.firstIndex(where: { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }) {
            // Show 1 completed before current (if any), then fill forward
            let start = max(0, nextIndex - 1)
            let end = min(tasks.count, start + maxCount)
            // If near the end, shift window back
            let adjustedStart = max(0, end - maxCount)
            return Array(tasks[adjustedStart..<end])
        }
        // All completed — show last N
        return Array(tasks.suffix(maxCount))
    }

    private func taskListSection(stage: Stage, visible: Bool) -> some View {
        let theme = stage.theme
        let nextTask = stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }
        let displayTasks = visibleTasks(for: stage)

        return VStack(alignment: .leading, spacing: 0) {
            // Header — slides from left
            HStack {
                Text("\(stage.chineseTitle) · Tasks")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Button {
                    if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                        paywallTarget = PaywallTarget(stageId: stage.id)
                        return
                    }
                    guard progress.isStageUnlocked(stageId: stage.id, subscription: subscription) else { return }
                    selectedStage = stage
                } label: {
                    Text("View all")
                        .font(.caption.bold())
                        .foregroundStyle(theme.startColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .opacity(visible ? 1 : 0)
            .offset(x: visible ? 0 : -40)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.05), value: visible)

            Divider().background(AppColors.border)
                .scaleEffect(x: visible ? 1 : 0, anchor: .leading)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: visible)

            // Task rows — deal from right with rotation
            ForEach(Array(displayTasks.enumerated()), id: \.element.id) { idx, task in
                let isCompleted = progress.isTaskCompleted(stageId: stage.id, taskId: task.id)
                let isCurrent = task.id == nextTask?.id
                let delay = 0.12 * Double(idx) + 0.15

                VStack(spacing: 0) {
                    Button {
                        if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                            paywallTarget = PaywallTarget(stageId: stage.id)
                            return
                        }
                        guard progress.isStageUnlocked(stageId: stage.id, subscription: subscription) else { return }
                        selectedTask = task
                    } label: {
                        HStack(spacing: 12) {
                            // Number badge with bounce
                            ZStack {
                                Circle()
                                    .fill(isCompleted ? theme.startColor : isCurrent ? theme.startColor.opacity(0.1) : AppColors.surface)
                                    .frame(width: 28, height: 28)
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                } else {
                                    Text("\(task.id)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(isCurrent ? theme.startColor : AppColors.tertiaryText)
                                }
                            }
                            .scaleEffect(visible ? 1 : 0.01)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay + 0.15), value: visible)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(isCompleted ? AppColors.tertiaryText : AppColors.primaryText)
                                Text(task.englishTitle)
                                    .font(.caption2).foregroundStyle(AppColors.tertiaryText)
                            }
                            .blur(radius: progress.isStageLocked(stageId: stage.id, subscription: subscription) ? 4 : 0)
                            .overlay {
                                if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColors.tertiaryText)
                                }
                            }

                            Spacer()

                            if isCurrent {
                                Text("Current")
                                    .font(.caption2.bold()).foregroundStyle(theme.startColor)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(theme.startColor.opacity(0.1)).clipShape(Capsule())
                                    .scaleEffect(visible ? 1 : 0.01)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay + 0.2), value: visible)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(AppColors.border)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .background(isCurrent ? theme.startColor.opacity(0.03) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if idx < displayTasks.count - 1 {
                        Divider().background(AppColors.border).padding(.leading, 52)
                    }
                }
                .opacity(visible ? 1 : 0)
                .offset(x: visible ? 0 : 80)
                .rotation3DEffect(.degrees(visible ? 0 : 12), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(delay), value: visible)
            }

            if stage.tasks.count > displayTasks.count {
                let footerDelay = 0.12 * Double(displayTasks.count) + 0.15
                VStack(spacing: 0) {
                    Divider().background(AppColors.border).padding(.leading, 52)
                    Button {
                        if progress.isStageLocked(stageId: stage.id, subscription: subscription) {
                            paywallTarget = PaywallTarget(stageId: stage.id)
                            return
                        }
                        guard progress.isStageUnlocked(stageId: stage.id, subscription: subscription) else { return }
                        selectedStage = stage
                    } label: {
                        HStack {
                            Text("View all \(stage.tasks.count) tasks")
                                .font(.caption.bold()).foregroundStyle(theme.startColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(theme.startColor)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                }
                .opacity(visible ? 1 : 0)
                .offset(x: visible ? 0 : 80)
                .rotation3DEffect(.degrees(visible ? 0 : 12), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(footerDelay), value: visible)
            }
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .cardShadow()
        // Card container entrance
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.88, anchor: .top)
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.0), value: visible)
    }

    // MARK: - Helpers
    private func greetingText() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default:      return "Good evening 👋"
        }
    }

    private func dateString() -> String {
        Self.headerDateFormatter.string(from: Date())
    }

    // MARK: - Completion Celebration
    private var completionCelebration: some View {
        VStack(spacing: 12) {
            Text("🎉").font(.system(size: 44))
            Text("All Tasks Completed!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
            Text("You've finished all \(totalTasks) speaking tasks. Amazing work!")
                .font(.caption)
                .foregroundStyle(AppColors.secondText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.success.opacity(0.2), lineWidth: 1)
        )
        .cardShadow()
    }
}

// MARK: - Stat Chip
struct StatChip: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .cardShadow()
    }
}

// MARK: - Carousel Hero Card (Pseudo-3D depth style)
struct CarouselStageCard: View {
    @Environment(ProgressManager.self) private var progress
    @Environment(SubscriptionManager.self) private var subscription
    let stage: Stage
    var onStageTap: () -> Void
    var onTaskTap: (SpeakingTask) -> Void

    // Micro-animations
    @State private var emojiFloat = false
    @State private var progressGlow = false
    @State private var shimmerOffset: CGFloat = -120

    private var completedCount: Int { progress.completedTaskCount(for: stage) }
    private var prog: Double { progress.stageProgress(for: stage) }
    private var theme: StageTheme { stage.theme }
    private var needsPurchase: Bool { progress.isStageLocked(stageId: stage.id, subscription: subscription) }
    private var isStageLocked: Bool { !progress.isStageUnlocked(stageId: stage.id, subscription: subscription) }
    private var nextTask: SpeakingTask? {
        stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }
    }

    var body: some View {
        Button(action: onStageTap) {
            ZStack(alignment: .leading) {
                // Multi-layer gradient for depth
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.startColor,
                                theme.endColor,
                                theme.endColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Ambient light reflection (top-left glow)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.18), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 260
                        )
                    )

                // Decorative depth circles with parallax
                GeometryReader { geo in
                    let midX = geo.frame(in: .global).midX
                    let screenMid = UIScreen.main.bounds.width / 2
                    let p = (midX - screenMid) / screenMid

                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 150)
                        .blur(radius: 2)
                        .offset(x: geo.size.width - 80 + p * 20, y: -50 + p * 8)
                    Circle()
                        .fill(.white.opacity(0.07))
                        .frame(width: 100)
                        .blur(radius: 1)
                        .offset(x: geo.size.width - 15 + p * 30, y: 65 - p * 12)
                    Circle()
                        .fill(theme.startColor.opacity(0.3))
                        .frame(width: 60)
                        .blur(radius: 20)
                        .offset(x: -20 + p * 15, y: geo.size.height - 40 + p * 6)
                }

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        HStack(spacing: 6) {
                            Text("STAGE \(stage.id)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .tracking(2.0)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.12))
                                .clipShape(Capsule())
                            if stage.id > 1 {
                                HStack(spacing: 3) {
                                    Image(systemName: subscription.isPro ? "crown.fill" : "lock.fill")
                                        .font(.system(size: 8, weight: .bold))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .tracking(1.0)
                                }
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.18))
                                .clipShape(Capsule())
                            }
                            if isStageLocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8, weight: .bold))
                                    Text("点击解锁")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.18))
                                .clipShape(Capsule())
                            }
                        }
                        Spacer()
                        Text(theme.emoji)
                            .font(.system(size: 40))
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            .offset(y: emojiFloat ? -4 : 4)
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: emojiFloat
                            )
                    }
                    .padding(.bottom, 16)

                    Text(stage.chineseTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.bottom, 5)
                    Text(stage.title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.bottom, 22)

                    HStack {
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.18)).frame(height: 6)
                                    Capsule().fill(.white)
                                        .frame(width: max(0, geo.size.width * prog), height: 6)
                                        .shadow(
                                            color: .white.opacity(progressGlow ? 0.7 : 0.25),
                                            radius: progressGlow ? 8 : 4,
                                            x: 0, y: 0
                                        )
                                }
                            }
                            .frame(height: 6)
                            .frame(maxWidth: 120)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: progressGlow
                            )

                            Text("\(completedCount)/\(stage.taskCount)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            if prog >= 1.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppColors.success)
                                Text("Completed")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.success)
                            } else if isStageLocked {
                                Image(systemName: needsPurchase ? "crown.fill" : "lock.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(needsPurchase ? Color(hex: "C89B3C") : AppColors.tertiaryText)
                                Text(needsPurchase ? "Get PRO" : "Locked")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(needsPurchase ? Color(hex: "C89B3C") : AppColors.tertiaryText)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.startColor)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(theme.startColor)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        .overlay {
                            if prog < 1.0 {
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.35), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 50)
                                .offset(x: shimmerOffset)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(24)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: theme.startColor.opacity(0.25), radius: 20, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            emojiFloat = true
            if prog > 0 { progressGlow = true }
            if prog < 1.0 {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 120
                }
            }
        }
    }
}

// MARK: - Paywall Target (for .sheet(item:))
struct PaywallTarget: Identifiable {
    let stageId: Int
    var id: Int { stageId }
}

// MARK: - Stage Identifiable + Hashable
extension Stage: Hashable {
    static func == (lhs: Stage, rhs: Stage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - SpeakingTask Hashable (for NavigationDestination)
extension SpeakingTask: Hashable {
    static func == (lhs: SpeakingTask, rhs: SpeakingTask) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
