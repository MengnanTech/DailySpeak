import SwiftUI

struct StageListView: View {
    @Environment(ProgressManager.self) private var progress
    @State private var selectedStage: Stage?
    @State private var selectedTask: SpeakingTask?
    @State private var carouselStageId: Int?

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
                        if let stageId = carouselStageId,
                           let stage = stages.first(where: { $0.id == stageId }) {
                            taskListSection(stage: stage)
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
            }
        }
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
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                Text("\(totalCompleted) done")
                    .font(.caption.bold()).foregroundStyle(AppColors.secondText)
            }
        }
    }

    // MARK: - Stage Carousel
    private var stageCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(stages) { stage in
                    CarouselStageCard(
                        stage: stage,
                        onStageTap: { selectedStage = stage },
                        onTaskTap: { selectedTask = $0 }
                    )
                    .frame(width: UIScreen.main.bounds.width - 40)
                    .id(stage.id)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $carouselStageId)
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(stages) { stage in
                let isActive = stage.id == (carouselStageId ?? currentStage.id)
                Capsule()
                    .fill(isActive ? stage.theme.startColor : AppColors.border)
                    .frame(width: isActive ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: carouselStageId)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Task List Section
    private func taskListSection(stage: Stage) -> some View {
        let theme = stage.theme
        let nextTask = stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }

        return VStack(alignment: .leading, spacing: 0) {
            // Header
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

            Divider().background(AppColors.border)

            // Task rows
            ForEach(Array(stage.tasks.prefix(4).enumerated()), id: \.element.id) { idx, task in
                let isCompleted = progress.isTaskCompleted(stageId: stage.id, taskId: task.id)
                let isCurrent = task.id == nextTask?.id

                Button { selectedTask = task } label: {
                    HStack(spacing: 12) {
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

            if stage.tasks.count > 4 {
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
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), theme.startColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .cardShadow()
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
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
