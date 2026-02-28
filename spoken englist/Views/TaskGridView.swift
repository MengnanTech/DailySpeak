import SwiftUI

struct TaskGridView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage

    @State private var selectedTask: SpeakingTask?
    @State private var appearAnimations = false

    private var theme: StageTheme { stage.theme }
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                stageHeader
                taskGrid
            }
            .padding(.bottom, 40)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(stage.chineseTitle)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .navigationDestination(item: $selectedTask) { task in
            TaskOverviewView(stage: stage, task: task)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appearAnimations = true }
        }
    }

    // MARK: - Stage Header
    private var stageHeader: some View {
        ZStack(alignment: .leading) {
            theme.gradient
                .clipShape(RoundedRectangle(cornerRadius: 20))

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 120)
                    .offset(x: geo.size.width - 60, y: -30)
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 80)
                    .offset(x: geo.size.width - 10, y: 50)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stage \(stage.id)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1)
                    Spacer()
                    Text(theme.emoji)
                        .font(.system(size: 36))
                }

                Text(stage.chineseTitle)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(stage.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                // Progress
                HStack(spacing: 12) {
                    let completed = progress.completedTaskCount(for: stage)
                    let prog = progress.stageProgress(for: stage)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.2)).frame(height: 5)
                            Capsule().fill(.white)
                                .frame(width: max(0, geo.size.width * prog), height: 5)
                        }
                    }
                    .frame(height: 5)

                    Text("\(completed)/\(stage.taskCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(minWidth: 30)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(height: 180)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    // MARK: - Task Grid
    private var taskGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(stage.taskCount) TASKS")
                .font(.caption.bold())
                .foregroundStyle(AppColors.tertiaryText)
                .tracking(1.2)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(stage.tasks.enumerated()), id: \.element.id) { index, task in
                    TaskGridCard(
                        stage: stage,
                        task: task,
                        index: index + 1
                    ) {
                        selectedTask = task
                    }
                    .opacity(appearAnimations ? 1 : 0)
                    .offset(y: appearAnimations ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.45).delay(0.1 + Double(index) * 0.06),
                        value: appearAnimations
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Task Grid Card
struct TaskGridCard: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask
    let index: Int
    let onTap: () -> Void

    private var theme: StageTheme { stage.theme }
    private var isCompleted: Bool {
        progress.isTaskCompleted(stageId: stage.id, taskId: task.id)
    }
    private var isLocked: Bool {
        !progress.isTaskUnlocked(stageId: stage.id, taskId: task.id, in: stage)
    }
    private var stepsDone: Int {
        progress.completedStepCount(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
    }

    var body: some View {
        Button(action: { if !isLocked { onTap() } }) {
            VStack(alignment: .leading, spacing: 0) {
                // Top row: number badge + status
                HStack {
                    ZStack {
                        if isCompleted {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 34, height: 34)
                        } else if isLocked {
                            Circle()
                                .fill(AppColors.border)
                                .frame(width: 34, height: 34)
                        } else {
                            Circle()
                                .fill(theme.gradient)
                                .frame(width: 34, height: 34)
                        }

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.tertiaryText)
                        } else {
                            Text("\(index)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    if !isLocked && !isCompleted && stepsDone > 0 {
                        Text("\(stepsDone)/\(task.steps.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(theme.startColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(theme.startColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 12)

                // Task title
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isLocked ? AppColors.tertiaryText : AppColors.primaryText)
                    .lineLimit(2)
                    .padding(.bottom, 3)

                Text(task.englishTitle)
                    .font(.caption2)
                    .foregroundStyle(AppColors.tertiaryText)
                    .lineLimit(1)
                    .padding(.bottom, 10)

                Spacer(minLength: 0)

                // Bottom: question type tag
                if !isLocked {
                    Text(task.questionType)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(theme.startColor.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.startColor.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .frame(height: 165)
            .background(isLocked ? AppColors.surface.opacity(0.7) : AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isCompleted
                            ? AppColors.success.opacity(0.3)
                            : isLocked
                                ? AppColors.border.opacity(0.5)
                                : theme.startColor.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .cardShadow()
            .opacity(isLocked ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// MARK: - SpeakingTask Hashable
extension SpeakingTask: Hashable {
    static func == (lhs: SpeakingTask, rhs: SpeakingTask) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
