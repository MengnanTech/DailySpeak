import SwiftUI

struct TaskOverviewView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var showLearning = false
    @State private var showCriteria = false
    @State private var appear = false

    private var theme: StageTheme { stage.theme }

    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        topBanner
                        strategyCard
                        stepsTimeline
                        Color.clear.frame(height: 70)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }

                startButton
            }

            if showCriteria {
                criteriaOverlay
                    .transition(.opacity)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text("Task \(task.id)")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)
                    Text("·")
                        .foregroundStyle(AppColors.tertiaryText)
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                }
            }
        }
        .navigationDestination(isPresented: $showLearning) {
            LearningFlowView(stage: stage, task: task)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    // MARK: - Top Banner
    private var topBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.softGradient)

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 80)
                    .offset(x: geo.size.width - 50, y: -15)
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 50)
                    .offset(x: -15, y: 55)
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Stage \(stage.id)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())

                        Text(task.questionType)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(task.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(task.englishTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: 10)
                Text(theme.emoji)
                    .font(.system(size: 34))
            }
            .padding(18)
        }
        .frame(height: 125)
        .heroShadow()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
    }

    // MARK: - Strategy Card
    private var strategyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FEF3C7"))
                        .frame(width: 30, height: 30)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "F59E0B"))
                }

                Text("答题策略")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                Text("Tips")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "F59E0B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "FEF3C7"))
                    .clipShape(Capsule())
            }

            // Tips
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "F59E0B"))
                            .frame(width: 20, height: 20)
                            .background(Color(hex: "FEF3C7"))
                            .clipShape(Circle())

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)

                    if index < task.tips.count - 1 {
                        Divider()
                            .background(AppColors.border.opacity(0.4))
                            .padding(.leading, 30)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
        )
        .cardShadow()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.45).delay(0.08), value: appear)
    }

    // MARK: - Steps Timeline
    private var stepsTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.caption)
                    .foregroundStyle(theme.startColor)
                Text("学习步骤")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                let done = progress.completedStepCount(
                    stageId: stage.id, taskId: task.id, totalSteps: task.steps.count
                )
                Text("\(done)/\(task.steps.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.startColor.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 16)

            ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                let isStepDone = progress.isStepCompleted(
                    stageId: stage.id, taskId: task.id, stepIndex: index
                )
                let isCurrent = index == progress.currentStepIndex(
                    stageId: stage.id, taskId: task.id, totalSteps: task.steps.count
                )
                let isLast = index == task.steps.count - 1

                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        ZStack {
                            if isStepDone {
                                Circle().fill(AppColors.success)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            } else if isCurrent {
                                Circle().fill(theme.startColor)
                                    .frame(width: 28, height: 28)
                                Circle().fill(.white)
                                    .frame(width: 10, height: 10)
                            } else {
                                Circle()
                                    .strokeBorder(AppColors.border, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }

                        if !isLast {
                            Rectangle()
                                .fill(isStepDone ? AppColors.success.opacity(0.3) : AppColors.border.opacity(0.5))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(step.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(
                                    isStepDone ? AppColors.primaryText :
                                    isCurrent ? theme.startColor :
                                    AppColors.tertiaryText
                                )

                            if isCurrent {
                                Circle()
                                    .fill(theme.startColor)
                                    .frame(width: 5, height: 5)
                            }
                        }

                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .padding(.bottom, isLast ? 0 : 20)
                    .padding(.top, 4)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 8)
                .animation(
                    .easeOut(duration: 0.4).delay(0.18 + Double(index) * 0.05),
                    value: appear
                )
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
        )
        .cardShadow()
    }

    // MARK: - Start Button (Sticky)
    private var startButton: some View {
        let currentStep = progress.currentStepIndex(
            stageId: stage.id,
            taskId: task.id,
            totalSteps: task.steps.count
        )
        let allDone = currentStep >= task.steps.count
        let label = allDone ? "Review Again" : (currentStep > 0 ? "Continue Learning" : "Start Learning")
        let icon = allDone ? "arrow.counterclockwise" : "arrow.right"

        return VStack(spacing: 0) {
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            Button {
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    showCriteria = true
                }
            } label: {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.subheadline.bold())
                    Image(systemName: icon)
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .heroShadow()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(AppColors.background)
        }
    }

    // MARK: - Criteria Overlay
    private var criteriaOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) { showCriteria = false }
                }

            VStack(spacing: 0) {
                // Gradient header
                ZStack {
                    theme.softGradient

                    GeometryReader { geo in
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 70)
                            .offset(x: geo.size.width - 40, y: -10)
                    }

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 48, height: 48)
                            Image(systemName: "target")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }

                        Text("过关标准")
                            .font(.headline.bold())
                            .foregroundStyle(.white)

                        Text("完成以下目标即可通过")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 18)
                }
                .frame(height: 135)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                )

                // List
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(task.passCriteria.enumerated()), id: \.offset) { index, criteria in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.startColor.opacity(0.08))
                                    .frame(width: 30, height: 30)
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.startColor)
                            }

                            Text(criteria)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()
                        }
                        .padding(.vertical, 9)

                        if index < task.passCriteria.count - 1 {
                            Divider()
                                .background(AppColors.border.opacity(0.4))
                                .padding(.leading, 42)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // Buttons
                VStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { showCriteria = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showLearning = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Got it, Let's Go")
                                .font(.subheadline.bold())
                            Image(systemName: "arrow.right")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(theme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(duration: 0.3)) { showCriteria = false }
                    } label: {
                        Text("Not yet")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppColors.shadowColor.opacity(0.15), radius: 5, x: 0, y: 2)
            .shadow(color: AppColors.shadowColor.opacity(0.12), radius: 30, x: 0, y: 12)
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
    }
}
