import SwiftUI

struct TaskGridView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage

    @State private var selectedTask: SpeakingTask?
    @State private var appearAnimations = false
    @State private var currentNodePulse = false

    private var theme: StageTheme { stage.theme }

    private var nextTask: SpeakingTask? {
        stage.tasks.first { !progress.isTaskCompleted(stageId: stage.id, taskId: $0.id) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                stageHeader
                progressSummary
                timelineList
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
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                currentNodePulse = true
            }
        }
    }

    // MARK: - Stage Header
    private var stageHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.softGradient)

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 90)
                    .offset(x: geo.size.width - 55, y: -20)
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 60)
                    .offset(x: -20, y: 65)
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stage \(stage.id)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1)

                    Text(stage.chineseTitle)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(stage.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                        .padding(.bottom, 4)

                    HStack(spacing: 6) {
                        let completed = progress.completedTaskCount(for: stage)
                        let prog = progress.stageProgress(for: stage)

                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.2)).frame(width: 80, height: 4)
                            Capsule().fill(.white)
                                .frame(width: max(0, 80 * prog), height: 4)
                        }

                        Text("\(completed)/\(stage.taskCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer(minLength: 10)

                Text(theme.emoji)
                    .font(.system(size: 38))
            }
            .padding(18)
        }
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .heroShadow(color: theme.start)
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    // MARK: - Progress Summary
    private var progressSummary: some View {
        let completed = progress.completedTaskCount(for: stage)
        let total = stage.taskCount

        return HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(completed > 0 ? AppColors.success : AppColors.tertiaryText)
            Text("\(completed)/\(total) completed")
                .font(.caption.bold())
                .foregroundStyle(AppColors.secondText)
            Spacer()
            Text("\(total) tasks")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Timeline List
    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(Array(stage.tasks.enumerated()), id: \.element.id) { index, task in
                let state = taskState(for: task)
                let isLast = index == stage.tasks.count - 1

                TimelineRow(
                    stage: stage,
                    task: task,
                    index: index + 1,
                    state: state,
                    isLast: isLast,
                    currentNodePulse: currentNodePulse,
                    onTap: { selectedTask = task }
                )
                .opacity(appearAnimations ? 1 : 0)
                .offset(y: appearAnimations ? 0 : 16)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.78).delay(0.08 + Double(index) * 0.06),
                    value: appearAnimations
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers
    private func taskState(for task: SpeakingTask) -> TaskState {
        if progress.isTaskCompleted(stageId: stage.id, taskId: task.id) {
            return .completed
        } else if task.id == nextTask?.id {
            return .current
        } else if progress.isTaskUnlocked(stageId: stage.id, taskId: task.id, in: stage) {
            return .unlocked
        } else {
            return .locked
        }
    }
}

// MARK: - Task State
enum TaskState {
    case completed, current, unlocked, locked
}

// MARK: - Timeline Row
struct TimelineRow: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask
    let index: Int
    let state: TaskState
    let isLast: Bool
    let currentNodePulse: Bool
    let onTap: () -> Void

    private var theme: StageTheme { stage.theme }

    var body: some View {
        Button(action: { if state != .locked { onTap() } }) {
            HStack(alignment: .top, spacing: 16) {
                // Left: timeline connector + node
                timelineColumn
                // Right: content
                contentColumn
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state == .locked)
    }

    // MARK: - Timeline Column
    private var timelineColumn: some View {
        VStack(spacing: 0) {
            // Node
            nodeView
            // Connector line
            if !isLast {
                Rectangle()
                    .fill(state == .completed ? theme.startColor.opacity(0.4) : AppColors.border)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 28)
    }

    @ViewBuilder
    private var nodeView: some View {
        let size: CGFloat = state == .current ? 28 : 24
        ZStack {
            switch state {
            case .completed:
                Circle()
                    .fill(theme.startColor)
                    .frame(width: size, height: size)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)

            case .current:
                Circle()
                    .fill(theme.startColor.opacity(0.15))
                    .frame(width: size + 10, height: size + 10)
                    .scaleEffect(currentNodePulse ? 1.15 : 1.0)
                Circle()
                    .fill(theme.gradient)
                    .frame(width: size, height: size)
                Text("\(index)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

            case .unlocked:
                Circle()
                    .strokeBorder(theme.startColor, lineWidth: 2)
                    .frame(width: size, height: size)
                Text("\(index)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.startColor)

            case .locked:
                Circle()
                    .fill(AppColors.border)
                    .frame(width: 22, height: 22)
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
    }

    // MARK: - Content Column
    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            if state == .current {
                currentTaskContent
            } else {
                compactTaskContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Compact Row (completed / unlocked / locked)
    private var compactTaskContent: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(state == .locked ? AppColors.tertiaryText : AppColors.primaryText)
                        .strikethrough(state == .completed, color: AppColors.tertiaryText.opacity(0.4))

                    Text(task.englishTitle)
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                Spacer()

                if state == .completed {
                    // No extra chip needed, checkmark on node is enough
                } else if state == .unlocked {
                    let stepsDone = progress.completedStepCount(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
                    if stepsDone > 0 {
                        Text("\(stepsDone)/\(task.steps.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.startColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(theme.startColor.opacity(0.08))
                            .clipShape(Capsule())
                    } else {
                        Text(task.questionType)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(theme.startColor.opacity(0.7))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(theme.startColor.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }

                if state != .locked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.border)
                }
            }
            .padding(.vertical, 14)
            .padding(.trailing, 4)
        }
    }

    // MARK: - Expanded Row (current task)
    private var currentTaskContent: some View {
        let stepsDone = progress.completedStepCount(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
        let nextStepIndex = progress.currentStepIndex(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
        let nextStep: LearningStep? = nextStepIndex < task.steps.count ? task.steps[nextStepIndex] : nil

        return VStack(alignment: .leading, spacing: 10) {
            // Title area
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                Text(task.englishTitle)
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondText)
            }
            .padding(.top, 10)

            // Steps progress bar
            HStack(spacing: 3) {
                ForEach(0..<task.steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i < stepsDone ? theme.startColor : theme.startColor.opacity(0.15))
                        .frame(height: 3)
                }
            }

            // Next step preview card
            if let step = nextStep {
                HStack(spacing: 10) {
                    Image(systemName: step.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.startColor)
                        .frame(width: 28, height: 28)
                        .background(theme.startColor.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text(stepsDone == 0 ? "Start" : "Next")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.tertiaryText)
                            .textCase(.uppercase)
                        Text(step.title)
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(stepsDone == 0 ? "Start" : "Continue")
                            .font(.caption.bold())
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.gradient)
                    .clipShape(Capsule())
                }
                .padding(12)
                .background(theme.startColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.startColor.opacity(0.1), lineWidth: 1)
                )
            } else {
                // All steps done but task not marked complete — show review
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.startColor)
                    Text("Review Again")
                        .font(.caption.bold())
                        .foregroundStyle(theme.startColor)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.startColor.opacity(0.5))
                }
                .padding(12)
                .background(theme.startColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.bottom, 16)
        .padding(.trailing, 4)
    }
}
