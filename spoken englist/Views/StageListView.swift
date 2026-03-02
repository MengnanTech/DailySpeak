import SwiftUI

struct StageListView: View {
    @Environment(ProgressManager.self) private var progress
    @State private var selectedStage: Stage?
    @State private var selectedTask: SpeakingTask?
    @State private var carouselStageId: Int?
    @State private var displayedTaskStageId: Int?
    @State private var taskListInsertionEdge: Edge = .trailing
    @State private var taskListStageVisibility: [Int: Bool] = [:]

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
                            .padding(.bottom, 28)

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
                TaskOverviewView(stage: stage, task: task)
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
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatChip(icon: "flame.fill", iconColor: Color(hex: "F97316"),
                     value: "\(totalCompleted)", label: "completed")
            StatChip(icon: "book.fill", iconColor: Color(hex: "5B9BF0"),
                     value: "\(totalTasks - totalCompleted)", label: "remaining")
            StatChip(icon: "chart.line.uptrend.xyaxis", iconColor: Color(hex: "10B981"),
                     value: "S\(currentStage.id)", label: "current")
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

    // MARK: - Stage Carousel
    private var stageCarousel: some View {
        GeometryReader { geo in
            let sidePeek = min(24, max(14, geo.size.width * 0.06))
            let itemSpacing = min(10, max(6, geo.size.width * 0.02))
            let cardWidth = max(0, geo.size.width - sidePeek * 2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: itemSpacing) {
                    ForEach(stages) { stage in
                        CarouselStageCard(
                            stage: stage,
                            onStageTap: { selectedStage = stage },
                            onTaskTap: { selectedTask = $0 }
                        )
                        .frame(width: cardWidth)
                        .scrollTransition(.animated(.spring(response: 0.6, dampingFraction: 0.72))) { content, phase in
                            content
                                .opacity(1 - min(0.22, abs(phase.value) * 0.22))
                                .scaleEffect(max(0.985, 1 - abs(phase.value) * 0.015))
                                .saturation(1 - min(0.12, abs(phase.value) * 0.12))
                                .brightness(-min(0.04, abs(phase.value) * 0.04))
                        }
                        .id(stage.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 24)
            }
            .contentMargins(.horizontal, sidePeek, for: .scrollContent)
            .scrollClipDisabled()
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $carouselStageId, anchor: .center)
        }
        .frame(height: 278)
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
    private func taskListSection(stage: Stage, visible: Bool) -> some View {
        let theme = stage.theme
        let nextTask = stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }

        return VStack(alignment: .leading, spacing: 0) {
            // Header — slides from left
            HStack {
                Text("\(stage.chineseTitle) · Tasks")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Button { selectedStage = stage } label: {
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
            ForEach(Array(stage.tasks.prefix(4).enumerated()), id: \.element.id) { idx, task in
                let isCompleted = progress.isTaskCompleted(stageId: stage.id, taskId: task.id)
                let isCurrent = task.id == nextTask?.id
                let delay = 0.12 * Double(idx) + 0.15

                VStack(spacing: 0) {
                    Button { selectedTask = task } label: {
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
                                    Text("\(idx + 1)")
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
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(isCurrent ? theme.startColor.opacity(0.03) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if idx < min(stage.tasks.count, 4) - 1 {
                        Divider().background(AppColors.border).padding(.leading, 52)
                    }
                }
                .opacity(visible ? 1 : 0)
                .offset(x: visible ? 0 : 80)
                .rotation3DEffect(.degrees(visible ? 0 : 12), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.72).delay(delay), value: visible)
            }

            if stage.tasks.count > 4 {
                let footerDelay = 0.12 * Double(min(stage.tasks.count, 4)) + 0.15
                VStack(spacing: 0) {
                    Divider().background(AppColors.border).padding(.leading, 52)
                    Button { selectedStage = stage } label: {
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
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: Date())
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

// MARK: - Carousel Hero Card (DailySpeak todayTaskCard style)
struct CarouselStageCard: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    var onStageTap: () -> Void
    var onTaskTap: (SpeakingTask) -> Void

    private var completedCount: Int { progress.completedTaskCount(for: stage) }
    private var prog: Double { progress.stageProgress(for: stage) }
    private var theme: StageTheme { stage.theme }
    private var nextTask: SpeakingTask? {
        stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }
    }

    var body: some View {
        Button(action: onStageTap) {
            ZStack(alignment: .leading) {
                // Gradient background
                LinearGradient(
                    colors: [theme.startColor, theme.endColor],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // Decorative circles
                GeometryReader { geo in
                    Circle().fill(.white.opacity(0.09)).frame(width: 130)
                        .offset(x: geo.size.width - 65, y: -40)
                    Circle().fill(.white.opacity(0.06)).frame(width: 90)
                        .offset(x: geo.size.width - 10, y: 70)
                }

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text("STAGE \(stage.id)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1.5)
                        Spacer()
                        Text(theme.emoji).font(.system(size: 36))
                    }
                    .padding(.bottom, 14)

                    Text(stage.chineseTitle)
                        .font(.title2.bold()).foregroundStyle(.white)
                        .padding(.bottom, 4)
                    Text(stage.title)
                        .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 20)

                    HStack {
                        // Progress
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.2)).frame(height: 5)
                                    Capsule().fill(.white)
                                        .frame(width: max(0, geo.size.width * prog), height: 5)
                                }
                            }
                            .frame(height: 5)
                            .frame(maxWidth: 120)

                            Text("\(completedCount)/\(stage.taskCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        // Continue button
                        HStack(spacing: 6) {
                            Text("Continue").font(.subheadline.bold())
                                .foregroundStyle(theme.startColor)
                            Image(systemName: "arrow.right").font(.caption.bold())
                                .foregroundStyle(theme.startColor)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(.white).clipShape(Capsule())
                    }
                }
                .padding(22)
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
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
