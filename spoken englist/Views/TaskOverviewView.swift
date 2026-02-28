import SwiftUI

struct TaskOverviewView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var showLearning = false
    @State private var appearAnimations = false

    private var theme: StageTheme { stage.theme }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                taskInfoCard
                passCriteriaCard
                timelineSection
                startButton
            }
            .padding(.bottom, 50)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Task \(task.id)")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .navigationDestination(isPresented: $showLearning) {
            LearningFlowView(stage: stage, task: task)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appearAnimations = true }
        }
    }

    // MARK: - Task Info Card
    private var taskInfoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header
            ZStack(alignment: .leading) {
                theme.gradient
                    .frame(height: 100)

                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 90)
                        .offset(x: geo.size.width - 50, y: -20)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stage \(stage.id) · Task \(task.id)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(0.8)

                        Text(task.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(theme.emoji)
                        .font(.system(size: 32))
                }
                .padding(.horizontal, 20)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )

            // Content
            VStack(alignment: .leading, spacing: 14) {
                // Question type
                Label(task.questionType, systemImage: "doc.text.fill")
                    .font(.caption.bold())
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.startColor.opacity(0.08))
                    .clipShape(Capsule())

                // Prompt
                Text(task.prompt)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText)
                    .italic()
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Meta info
                HStack(spacing: 16) {
                    metaTag(icon: "clock.fill", text: task.suggestedTime)
                    Spacer()
                    metaTag(icon: "chart.bar.fill", text: task.difficulty)
                }
            }
            .padding(18)
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .cardShadow()
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 15)
    }

    private func metaTag(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.secondText)
        }
    }

    // MARK: - Pass Criteria Card
    private var passCriteriaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.startColor)
                Text("过关标准")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(task.passCriteria, id: \.self) { criteria in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(theme.startColor.opacity(0.2))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(theme.startColor)
                            )
                        Text(criteria)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appearAnimations)
    }

    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LEARNING STEPS")
                .font(.caption.bold())
                .foregroundStyle(AppColors.tertiaryText)
                .tracking(1.2)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            VStack(spacing: 0) {
                ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                    TimelineStepRow(
                        step: step,
                        index: index,
                        isLast: index == task.steps.count - 1,
                        isCompleted: progress.isStepCompleted(
                            stageId: stage.id,
                            taskId: task.id,
                            stepIndex: index
                        ),
                        isCurrent: index == progress.currentStepIndex(
                            stageId: stage.id,
                            taskId: task.id,
                            totalSteps: task.steps.count
                        ),
                        accentColor: theme.startColor
                    )
                    .opacity(appearAnimations ? 1 : 0)
                    .offset(y: appearAnimations ? 0 : 15)
                    .animation(
                        .easeOut(duration: 0.45).delay(0.2 + Double(index) * 0.08),
                        value: appearAnimations
                    )
                }
            }
            .padding(18)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .cardShadow()
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 28)
    }

    // MARK: - Start Button
    private var startButton: some View {
        let currentStep = progress.currentStepIndex(
            stageId: stage.id,
            taskId: task.id,
            totalSteps: task.steps.count
        )
        let allDone = currentStep >= task.steps.count
        let buttonText = allDone ? "Review Again" : (currentStep > 0 ? "Continue Learning" : "Start Learning")

        return Button {
            showLearning = true
        } label: {
            HStack(spacing: 10) {
                Text(buttonText)
                    .font(.headline.bold())
                Image(systemName: allDone ? "arrow.counterclockwise" : "arrow.right")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(theme.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .heroShadow(color: theme.start)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: appearAnimations)
    }
}

// MARK: - Timeline Step Row
struct TimelineStepRow: View {
    let step: LearningStep
    let index: Int
    let isLast: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else if isCurrent {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                    } else {
                        Circle()
                            .fill(AppColors.surface)
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(AppColors.border)
                            .frame(width: 10, height: 10)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? AppColors.success.opacity(0.3) : AppColors.border)
                        .frame(width: 2, height: 46)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(step.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(
                            isCurrent ? accentColor :
                            isCompleted ? AppColors.secondText :
                            AppColors.tertiaryText
                        )

                    if isCurrent {
                        Text("Current")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text(step.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.bottom, isLast ? 0 : 18)

                HStack(spacing: 4) {
                    Image(systemName: step.icon)
                        .font(.caption2)
                    Text(step.type.englishTitle)
                        .font(.caption2)
                }
                .foregroundStyle(
                    isCurrent ? accentColor.opacity(0.6) : AppColors.tertiaryText.opacity(0.6)
                )
                .padding(.bottom, isLast ? 0 : 10)
            }
            .padding(.top, 4)
        }
    }
}
