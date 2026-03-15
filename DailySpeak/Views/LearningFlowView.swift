import SwiftUI
import AVFoundation

struct LearningFlowView: View {
    @Environment(ProgressManager.self) private var progress
    @Environment(\.dismiss) private var dismiss
    let stage: Stage
    let task: SpeakingTask

    @State private var currentStep: Int
    @State private var stepTransitionDirection: Edge = .trailing
    @State private var stepCanComplete = false
    @State private var stepProgressHint: String?

    private var theme: StageTheme { stage.theme }
    private var steps: [LearningStep] { task.steps }

    var initialStep: Int?

    init(stage: Stage, task: SpeakingTask, initialStep: Int? = nil) {
        self.stage = stage
        self.task = task
        self.initialStep = initialStep
        _currentStep = State(initialValue: 0)
    }

    private func isStepUnlocked(_ index: Int) -> Bool {
        if index == 0 { return true }
        return progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            stepContent
            bottomBar
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(steps[currentStep].type.color)
                    Text(steps[currentStep].title)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
        .onAppear {
            syncCurrentStep()
            progress.startStudySession()
        }
        .onDisappear {
            EnglishSpeechPlayer.shared.stopPlayback()
            progress.endStudySession()
        }
        .onChange(of: currentStep) { _, _ in
            stepCanComplete = false
            stepProgressHint = nil
        }
    }

    private func syncCurrentStep() {
        if let initial = initialStep, initial >= 0, initial < steps.count {
            currentStep = initial
        } else {
            let saved = progress.currentStepIndex(
                stageId: stage.id,
                taskId: task.id,
                totalSteps: steps.count
            )
            currentStep = min(saved, steps.count - 1)
        }
    }

    // MARK: - Step Indicator (Enhanced)
    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                let isCompleted = progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index)
                let isCurrent = index == currentStep
                let isLocked = !isStepUnlocked(index)

                Button {
                    guard !isLocked else { return }
                    let dir: Edge = index > currentStep ? .trailing : .leading
                    stepTransitionDirection = dir
                    withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                        currentStep = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isCompleted {
                                Circle()
                                    .fill(AppColors.success)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            } else if isCurrent {
                                Circle()
                                    .fill(steps[index].type.color)
                                    .frame(width: 22, height: 22)
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            } else if isLocked {
                                Circle()
                                    .fill(AppColors.border.opacity(0.5))
                                    .frame(width: 22, height: 22)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(AppColors.tertiaryText)
                            } else {
                                Circle()
                                    .strokeBorder(steps[index].type.color.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(steps[index].type.color.opacity(0.6))
                            }
                        }

                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                isCurrent
                                    ? steps[index].type.color
                                    : isCompleted
                                        ? AppColors.success
                                        : Color.clear
                            )
                            .frame(height: 3)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .opacity(isLocked ? 0.5 : 1)
                .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(AppColors.card)
    }

    // MARK: - Step Content (locked steps show lock overlay)
    private var stepContent: some View {
        TabView(selection: $currentStep) {
            ForEach(0..<steps.count, id: \.self) { index in
                Group {
                    if isStepUnlocked(index) {
                        ScrollView(showsIndicators: false) {
                            stepView(for: steps[index].type)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                                .padding(.bottom, 100)
                        }
                    } else {
                        lockedStepOverlay(step: steps[index], index: index)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(duration: 0.4, bounce: 0.12), value: currentStep)
    }

    private func lockedStepOverlay(step: LearningStep, index: Int) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(step.type.color.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(step.type.color.opacity(0.05))
                    .frame(width: 70, height: 70)
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(step.type.color.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text("Complete Step \(index) to unlock")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Button {
                stepTransitionDirection = .leading
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                    currentStep = index - 1
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption.bold())
                    Text("Go to Step \(index)")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(step.type.color)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(step.type.color.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    @ViewBuilder
    private func stepView(for type: StepType) -> some View {
        switch type {
        case .strategy:   StrategyStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .review:     ReviewStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .vocabulary:  VocabularyStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .phrases:     PhrasesStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .framework:   FrameworkStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .samples:     SamplesStepView(task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        case .practice:    PracticePromptView(stageId: stage.id, task: task, accentColor: theme.startColor, canComplete: $stepCanComplete, progressHint: $stepProgressHint)
        }
    }

    // MARK: - Bottom Bar (Enhanced with step locking + completion gate)
    private var bottomBar: some View {
        let isCurrentCompleted = progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: currentStep)
        let isLastStep = currentStep == steps.count - 1
        let canProceed = isCurrentCompleted || stepCanComplete

        return VStack(spacing: 0) {
            // Progress hint when step not yet completable
            if !canProceed, let hint = stepProgressHint {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(hint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(steps[currentStep].type.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(steps[currentStep].type.color.opacity(0.08))
            }

            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button {
                        stepTransitionDirection = .leading
                        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                            currentStep -= 1
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(AppColors.secondText)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    markCurrentComplete()
                    if isLastStep {
                        finishTask()
                    } else {
                        stepTransitionDirection = .trailing
                        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                            currentStep += 1
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if !isCurrentCompleted && canProceed {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 13, weight: .bold))
                        }
                        if !canProceed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(
                            !canProceed
                                ? "完成本步骤内容"
                                : isLastStep
                                    ? "Complete"
                                    : isCurrentCompleted
                                        ? "Next"
                                        : "Mark Complete & Next"
                        )
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        if canProceed {
                            Image(systemName: isLastStep ? "checkmark" : "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        !canProceed
                            ? AnyShapeStyle(AppColors.border)
                            : isLastStep
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [AppColors.success, AppColors.success.opacity(0.8)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(theme.gradient)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .shadow(color: canProceed ? (isLastStep ? AppColors.success : theme.startColor).opacity(0.3) : .clear, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!canProceed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            AppColors.card
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func markCurrentComplete() {
        progress.completeStep(stageId: stage.id, taskId: task.id, stepIndex: currentStep)
    }

    private func finishTask() {
        progress.completeTask(stageId: stage.id, taskId: task.id)
        dismiss()
    }
}

// MARK: - Step Hero Header (Enhanced with shimmer and depth)
struct StepHeroHeader: View {
    let icon: String
    let title: String
    let english: String
    let subtitle: String
    let accentColor: Color
    var secondaryColor: Color? = nil

    @State private var shimmer = false

    private var endColor: Color { secondaryColor ?? accentColor.opacity(0.7) }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accentColor, endColor, accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.15), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 100)
                    .blur(radius: 1)
                    .offset(x: geo.size.width - 55, y: -30)
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 65)
                    .offset(x: geo.size.width - 20, y: 45)
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 40)
                    .blur(radius: 12)
                    .offset(x: -10, y: geo.size.height - 20)
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(english.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .tracking(1.5)

                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .symbolEffect(.pulse, options: .repeating.speed(0.5))
                }
            }
            .padding(20)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: accentColor.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

struct LessonStepHeader: View {
    let label: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(accentColor)
                .tracking(1.3)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.08))
                .clipShape(Capsule())

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Staggered Animation Modifier (Enhanced)
struct StaggeredAppear: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 22)
            .scaleEffect(appeared ? 1 : 0.97, anchor: .top)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.8).delay(0.07 * Double(index) + 0.08),
                value: appeared
            )
    }
}

extension View {
    func staggerIn(index: Int, appeared: Bool) -> some View {
        modifier(StaggeredAppear(index: index, appeared: appeared))
    }
}

// MARK: - Strategy Step
struct StrategyStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedAudioIds: Set<String> = []
    private var lesson: LessonContent? { task.lessonContent }

    // The prompt is the main English content to listen to
    private var promptPlaybackId: String {
        EnglishSpeechPlayer.playbackID(for: task.prompt)
    }

    private var requiredAudioIds: Set<String> {
        if let lesson {
            // Lesson mode: angles + sequence
            var ids: Set<String> = []
            for angle in lesson.strategy.angles {
                let text = angle.title + ". " + angle.content.joined(separator: ". ")
                ids.insert(EnglishSpeechPlayer.playbackID(for: text, category: "angle"))
            }
            for item in lesson.strategy.sequence {
                let text = "\(item.phase). \(item.focus). \(item.target)"
                ids.insert(EnglishSpeechPlayer.playbackID(for: text, category: "sequence"))
            }
            return ids
        }
        // Standard mode: prompt + all tips
        var ids: Set<String> = [promptPlaybackId]
        for tip in task.tips {
            ids.insert(EnglishSpeechPlayer.playbackID(for: tip, category: "tip"))
        }
        return ids
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "先搭答案骨架",
                    subtitle: "先定人物关系和特质，再用一个故事收住影响。",
                    accentColor: Color(hex: "F59E0B")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "lightbulb.max.fill",
                    title: "答题策略",
                    english: "Strategy & Tips",
                    subtitle: "了解如何组织你的回答，掌握答题思路",
                    accentColor: Color(hex: "F59E0B"),
                    secondaryColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            if let lesson {
                lessonStrategyContent(lesson)
            } else {
                standardStrategyContent
            }
        }
        .onAppear {
            appeared = true
            updateStrategyProgress()
        }
        .onChange(of: listenedAudioIds.count) { _, _ in
            updateStrategyProgress()
        }
    }

    private func updateStrategyProgress() {
        let remaining = requiredAudioIds.subtracting(listenedAudioIds).count
        if remaining == 0 {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "还剩 \(remaining) 个语音未听"
        }
    }

    private let stepColor = Color(hex: "F59E0B")

    private var standardStrategyContent: some View {
        Group {
            GradientAccentCard(color: stepColor) {
                StepSectionLabel(icon: "lightbulb.fill", title: "答题思路", color: stepColor)

                ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                    VStack(alignment: .leading, spacing: 8) {
                        NumberedItemRow(index: index + 1, text: tip, color: stepColor)

                        HStack(spacing: 8) {
                            InlineAudioPlayerControl(
                                text: tip,
                                playbackID: EnglishSpeechPlayer.playbackID(for: tip, category: "tip"),
                                sourceLabel: "Tip",
                                accentColor: stepColor,
                                style: .compact,
                                onPlay: { listenedAudioIds.insert(EnglishSpeechPlayer.playbackID(for: tip, category: "tip")) }
                            )
                            TranslateButton(englishText: tip, accentColor: stepColor)
                        }
                    }
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(stepColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("TOPIC")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(stepColor)
                        .tracking(1.2)
                }

                Text(task.prompt)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText)
                    .italic()
                    .lineSpacing(4)

                TranslateButton(englishText: task.prompt, accentColor: stepColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    AppColors.card
                    LinearGradient(
                        colors: [stepColor.opacity(0.06), stepColor.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(stepColor.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: stepColor.opacity(0.08), radius: 10, x: 0, y: 4)
            .staggerIn(index: 2, appeared: appeared)

            GradientAccentCard(color: Color(hex: "EF4444")) {
                StepSectionLabel(icon: "target", title: "过关标准", color: Color(hex: "EF4444"))

                ForEach(task.passCriteria, id: \.self) { criteria in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.success)
                                .padding(.top, 1)
                            Text(criteria)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }

                        TranslateButton(englishText: criteria, accentColor: Color(hex: "EF4444"))
                    }
                    .padding(.vertical, 2)
                }
            }
            .staggerIn(index: 3, appeared: appeared)
        }
    }

    private func lessonStrategyContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Angles — flat layout, no nested cards
            VStack(alignment: .leading, spacing: 20) {
                StepSectionLabel(
                    icon: "brain.head.profile",
                    title: "先想这 \(lesson.strategy.angles.count) 点",
                    color: stepColor
                )

                ForEach(Array(lesson.strategy.angles.enumerated()), id: \.offset) { index, angle in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(stepColor)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text(angle.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                TranslateButton(englishText: angle.title, accentColor: stepColor)
                            }
                        }

                        ForEach(angle.content, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(stepColor.opacity(0.35))
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 7)
                                    Text(item)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(2)
                                }
                                TranslateButton(englishText: item, accentColor: stepColor)
                                    .padding(.leading, 13)
                            }
                            .padding(.leading, 36)
                        }

                        // Audio for entire angle
                        let angleText = angle.title + ". " + angle.content.joined(separator: ". ")
                        let anglePlaybackId = EnglishSpeechPlayer.playbackID(for: angleText, category: "angle")
                        InlineAudioPlayerControl(
                            text: angleText,
                            playbackID: anglePlaybackId,
                            sourceLabel: "Strategy Angle",
                            accentColor: stepColor,
                            style: .compact,
                            onPlay: { listenedAudioIds.insert(anglePlaybackId) }
                        )

                        if index < lesson.strategy.angles.count - 1 {
                            Divider().background(AppColors.border.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 1, appeared: appeared)

            VStack(alignment: .leading, spacing: 16) {
                StepSectionLabel(icon: "arrow.right.circle.fill", title: "按这个顺序说", color: stepColor)

                ForEach(Array(lesson.strategy.sequence.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(stepColor)
                                .frame(width: 24, height: 24)
                                .background(stepColor.opacity(0.1))
                                .clipShape(Circle())
                            if index < lesson.strategy.sequence.count - 1 {
                                Rectangle()
                                    .fill(stepColor.opacity(0.12))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(item.phase)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                Text(item.focus)
                                    .font(.caption)
                                    .foregroundStyle(stepColor)
                            }
                            Text(item.target)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            TranslateButton(englishText: "\(item.phase): \(item.target)", accentColor: stepColor)

                            let seqText = "\(item.phase). \(item.focus). \(item.target)"
                            let seqPlaybackId = EnglishSpeechPlayer.playbackID(for: seqText, category: "sequence")
                            InlineAudioPlayerControl(
                                text: seqText,
                                playbackID: seqPlaybackId,
                                sourceLabel: "Strategy Sequence",
                                accentColor: stepColor,
                                style: .compact,
                                onPlay: { listenedAudioIds.insert(seqPlaybackId) }
                            )
                        }
                        .padding(.bottom, index < lesson.strategy.sequence.count - 1 ? 10 : 0)
                    }
                }

                Divider().background(AppColors.border)

                StepSectionLabel(icon: "chart.bar.fill", title: "内容分配", color: stepColor)

                ForEach(lesson.strategy.contentRatio, id: \.label) { ratio in
                    HStack {
                        Text(ratio.label)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                        Spacer()
                        Text(ratio.value)
                            .font(.caption.bold())
                            .foregroundStyle(stepColor)
                    }
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 2, appeared: appeared)
        }
    }
}

// MARK: - Vocabulary Step
private enum VocabCategory: String, CaseIterable {
    case core
    case extended

    var title: String {
        switch self {
        case .core: "核心词汇"
        case .extended: "扩展词汇"
        }
    }

    var icon: String {
        switch self {
        case .core: "textbook.fill"
        case .extended: "sparkles"
        }
    }
}

private enum VocabViewMode: String, CaseIterable {
    case list
    case flashcard

    var icon: String {
        switch self {
        case .list: "list.bullet"
        case .flashcard: "rectangle.on.rectangle.angled"
        }
    }

    var label: String {
        switch self {
        case .list: "列表"
        case .flashcard: "闪卡"
        }
    }
}

struct VocabularyStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var selectedCategory: VocabCategory = .core
    @State private var selectedItem: VocabItem?
    @State private var showUpgrade = true
    @State private var showAdvanced = false
    @State private var viewMode: VocabViewMode = .list
    @State private var flashcardIndex = 0
    @State private var flashcardFlipped = false
    @State private var appeared = false
    @State private var revealedWords: Set<String> = []
    @State private var listenedWords: Set<String> = []
    private var hasLessonContent: Bool { task.lessonContent != nil }

    private var coreItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .core }
    }

    private var upgradeItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .upgrade }
    }

    private var advancedItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .advanced }
    }

    private var currentFlashcardItems: [VocabItem] {
        selectedCategory == .core ? coreItems : (upgradeItems + advancedItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "核心词汇",
                    subtitle: "先抓最常用的描述词，再补更成熟的升级表达。",
                    accentColor: Color(hex: "4A90D9")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "character.book.closed.fill",
                    title: "核心词汇",
                    english: "Key Vocabulary",
                    subtitle: "掌握 \(coreItems.count) 个核心词 · \(upgradeItems.count + advancedItems.count) 个进阶词",
                    accentColor: Color(hex: "4A90D9"),
                    secondaryColor: Color(hex: "7AB4E8")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Mode switcher: List / Flashcard
            HStack(spacing: 0) {
                ForEach(VocabViewMode.allCases, id: \.self) { mode in
                    let isSelected = viewMode == mode
                    Button {
                        withAnimation(.spring(duration: 0.28)) { viewMode = mode; flashcardIndex = 0; flashcardFlipped = false }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(mode.label)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(isSelected ? .white : AppColors.secondText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(isSelected ? accentColor : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .staggerIn(index: 1, appeared: appeared)

            // Category switcher
            categorySwitcher
                .staggerIn(index: 2, appeared: appeared)

            if viewMode == .flashcard {
                flashcardView
                    .staggerIn(index: 3, appeared: appeared)
            } else {
                if selectedCategory == .core {
                    vocabList(items: coreItems)
                        .staggerIn(index: 3, appeared: appeared)
                } else {
                    extendedSectionCard
                        .staggerIn(index: 3, appeared: appeared)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            VocabDetailSheet(item: item, accentColor: accentColor)
                .presentationBackground(AppColors.background)
        }
        .onAppear {
            appeared = true
            updateVocabProgress()
        }
        .onChange(of: revealedWords.count) { _, _ in
            updateVocabProgress()
        }
        .onChange(of: listenedWords.count) { _, _ in
            updateVocabProgress()
        }
    }

    private var allCoreWords: Set<String> {
        Set(coreItems.map { $0.word })
    }

    private func updateVocabProgress() {
        let total = allCoreWords.count
        let revealed = allCoreWords.intersection(revealedWords).count
        let listened = allCoreWords.intersection(listenedWords).count
        if revealed >= total && listened >= total {
            canComplete = true
            progressHint = nil
        } else if listened < total {
            canComplete = false
            progressHint = "还剩 \(total - listened) 个核心词发音未听"
        } else {
            canComplete = false
            progressHint = "还剩 \(total - revealed) 个核心词汇未学习"
        }
    }

    // MARK: - Flashcard View (Enhanced 3D flip)
    private var flashcardView: some View {
        let items = currentFlashcardItems
        guard !items.isEmpty else {
            return AnyView(
                Text("No vocabulary items")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            )
        }
        let item = items[flashcardIndex % items.count]

        return AnyView(
            VStack(spacing: 18) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        flashcardFlipped.toggle()
                        if flashcardFlipped {
                            revealedWords.insert(item.word)
                        }
                    }
                } label: {
                    ZStack {
                        if !flashcardFlipped {
                            VStack(spacing: 14) {
                                Text(item.word)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryText)

                                if !item.phonetic.isEmpty {
                                    Text(item.phonetic)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                Text(item.partOfSpeech)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(item.band.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(item.band.color.opacity(0.1))
                                    .clipShape(Capsule())

                                Spacer().frame(height: 6)

                                HStack(spacing: 4) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: 10))
                                    Text("tap to flip")
                                        .font(.caption2)
                                }
                                .foregroundStyle(AppColors.tertiaryText.opacity(0.7))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.word)
                                        .font(.headline)
                                        .foregroundStyle(AppColors.primaryText)
                                    Spacer()
                                    Button {
                                        WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48, sourceLabel: "Vocabulary")
                                        listenedWords.insert(item.word)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(item.band.color)
                                            .frame(width: 34, height: 34)
                                            .background(item.band.color.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(item.meaning)
                                    .font(.title3.bold())
                                    .foregroundStyle(accentColor)

                                if !item.englishMeaning.isEmpty {
                                    Text(item.englishMeaning)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondText)
                                }

                                if let sourceBand = item.sourceBand ?? item.nativeNote {
                                    Text(sourceBand)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                Divider().background(AppColors.border)

                                if !item.example.isEmpty {
                                    Text(item.example)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.primaryText)
                                        .italic()
                                        .lineSpacing(3)
                                }

                                if !item.exampleTranslation.isEmpty {
                                    Text(item.exampleTranslation)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 240)
                    .padding(26)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                flashcardFlipped
                                    ? item.band.color.opacity(0.2)
                                    : AppColors.border.opacity(0.4),
                                lineWidth: 1
                            )
                    )
                    .rotation3DEffect(
                        .degrees(flashcardFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .shadow(color: accentColor.opacity(0.12), radius: 18, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                HStack(spacing: 18) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            flashcardFlipped = false
                            flashcardIndex = (flashcardIndex - 1 + items.count) % items.count
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.secondText)
                            .frame(width: 46, height: 46)
                            .background(AppColors.surface)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    Text("\(flashcardIndex % items.count + 1) / \(items.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.secondText)
                        .frame(minWidth: 60)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            flashcardFlipped = false
                            flashcardIndex = (flashcardIndex + 1) % items.count
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(accentColor)
                            .clipShape(Circle())
                            .shadow(color: accentColor.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        )
    }

    private var categorySwitcher: some View {
        HStack(spacing: 10) {
            ForEach(VocabCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                let count = category == .core ? coreItems.count : (upgradeItems.count + advancedItems.count)

                Button {
                    withAnimation(.spring(duration: 0.28)) {
                        selectedCategory = category
                        flashcardIndex = 0
                        flashcardFlipped = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(category.title)
                            .font(.subheadline.bold())
                        Text("\(count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.white.opacity(isSelected ? 0.22 : 0.08))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(isSelected ? .white : AppColors.secondText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        if isSelected {
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            AppColors.card
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border.opacity(isSelected ? 0.0 : 0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var extendedSectionCard: some View {
        VStack(spacing: 10) {
            DisclosureGroup(isExpanded: $showUpgrade) {
                VStack(spacing: 10) {
                    vocabList(items: upgradeItems)
                }
                .padding(.top, 10)
            } label: {
                sectionTag(title: "进阶词汇", count: upgradeItems.count, color: Color(hex: "F59E0B"), caption: "日常表达升级")
            }

            Divider().background(AppColors.border.opacity(0.35))

            DisclosureGroup(isExpanded: $showAdvanced) {
                VStack(spacing: 10) {
                    vocabList(items: advancedItems)
                }
                .padding(.top, 10)
            } label: {
                sectionTag(title: "高分词汇", count: advancedItems.count, color: Color(hex: "EF4444"), caption: "高阶表达与观点深度")
            }
        }
    }

    private func sectionTag(title: String, count: Int, color: Color, caption: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
            Spacer()
            Text(caption)
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
        }
    }

    private func vocabList(items: [VocabItem]) -> some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                VocabCardView(
                    item: item,
                    onShowMeaning: {
                        selectedItem = item
                        revealedWords.insert(item.word)
                    },
                    onPronounce: { WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48, sourceLabel: "Vocabulary"); listenedWords.insert(item.word) }
                )
            }
        }
    }
}

struct VocabCardView: View {
    let item: VocabItem
    let onShowMeaning: () -> Void
    let onPronounce: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.word)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    HStack(spacing: 8) {
                        if !item.phonetic.isEmpty {
                            Text(item.phonetic)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.secondText)
                        }

                        Text(item.partOfSpeech)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(item.band.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.band.color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    onPronounce()
                } label: {
                    ZStack {
                        Circle()
                            .fill(item.band.color.opacity(0.1))
                            .frame(width: 38, height: 38)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(item.band.color)
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button {
                    onShowMeaning()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("释义")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(item.band.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(item.band.color.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.band.bandLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                    if let sourceBand = item.sourceBand {
                        Text(sourceBand)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(item.band.color)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.band.color.opacity(0.4))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(item.band.color.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: item.band.color.opacity(0.08), radius: 10, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct VocabDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: VocabItem
    let accentColor: Color

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(item.word)
                                .font(.title2.bold())
                                .foregroundStyle(AppColors.primaryText)
                            if !item.phonetic.isEmpty {
                                Text(item.phonetic)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                            Text(item.partOfSpeech)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text(item.meaning)
                            .font(.headline)
                            .foregroundStyle(accentColor)

                        if !item.englishMeaning.isEmpty {
                            Text(item.englishMeaning)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)

                            HStack(spacing: 8) {
                                InlineAudioPlayerControl(
                                    text: item.englishMeaning,
                                    playbackID: EnglishSpeechPlayer.playbackID(for: item.englishMeaning, category: "vocab-meaning"),
                                    sourceLabel: "Vocab Meaning",
                                    accentColor: accentColor,
                                    style: .compact
                                )
                                TranslateButton(englishText: item.englishMeaning, accentColor: accentColor)
                            }
                        }

                        if let sourceBand = item.sourceBand {
                            Text(sourceBand)
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.tertiaryText)
                        }

                        if let nativeNote = item.nativeNote {
                            Text(nativeNote)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("发音")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

                        HStack(spacing: 10) {
                            pronunciationButton(title: "US", icon: "waveform") {
                                WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48, sourceLabel: "Vocabulary")
                            }
                            pronunciationButton(title: "UK", icon: "waveform.path.ecg") {
                                WordPronouncer.shared.speak(item.word, locale: "en-GB", rate: 0.48, sourceLabel: "Vocabulary")
                            }
                            pronunciationButton(title: "Slow", icon: "tortoise.fill") {
                                WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.34, sourceLabel: "Vocabulary")
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()

                    if !item.example.isEmpty || !item.exampleTranslation.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("例句")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                            if !item.example.isEmpty {
                                Text(item.example)
                                    .font(.body)
                                    .foregroundStyle(AppColors.primaryText)

                                InlineAudioPlayerControl(
                                    text: item.example,
                                    playbackID: EnglishSpeechPlayer.playbackID(for: item.example, category: "vocab-example"),
                                    sourceLabel: "Vocab Example",
                                    accentColor: accentColor,
                                    style: .compact
                                )
                            }
                            if !item.exampleTranslation.isEmpty {
                                Text(item.exampleTranslation)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .cardShadow()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
    }

    private func pronunciationButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

final class WordPronouncer {
    static let shared = WordPronouncer()

    private init() {}

    func speak(_ text: String, locale: String, rate: Float, sourceLabel: String = "English Audio") {
        guard !text.isEmpty else { return }
        guard locale.lowercased().hasPrefix("en") else { return }
        EnglishSpeechPlayer.shared.togglePlayback(
            id: playbackID(for: text, locale: locale, rate: rate),
            text: text,
            sourceLabel: sourceLabel
        )
    }

    func playbackID(for text: String, locale _: String, rate _: Float) -> String {
        EnglishSpeechPlayer.playbackID(for: text)
    }
}

// MARK: - Phrases Step
struct PhrasesStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedPhrases: Set<String> = []
    private var hasLessonContent: Bool { task.lessonContent != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "实用词组",
                    subtitle: "用短语拉开自然度，避免一句一句直译。",
                    accentColor: Color(hex: "10B981")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "quote.bubble.fill",
                    title: "实用词组",
                    english: "Useful Phrases",
                    subtitle: "掌握 \(task.phrases.count) 个地道表达，让口语更自然",
                    accentColor: Color(hex: "10B981"),
                    secondaryColor: Color(hex: "34D399")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Phrases count badge
            HStack(spacing: 8) {
                Image(systemName: "text.quote")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "10B981"))
                Text("\(listenedPhrases.count)/\(task.phrases.count) 个表达已听")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "10B981"))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "10B981").opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .staggerIn(index: 1, appeared: appeared)

            ForEach(Array(task.phrases.enumerated()), id: \.element.id) { index, phrase in
                PhraseCard(phrase: phrase, index: index + 1, accentColor: accentColor, onListen: {
                    listenedPhrases.insert(phrase.phrase)
                })
                    .staggerIn(index: index + 2, appeared: appeared)
            }
        }
        .onAppear {
            appeared = true
            updatePhrasesProgress()
        }
        .onChange(of: listenedPhrases.count) { _, _ in
            updatePhrasesProgress()
        }
    }

    private func updatePhrasesProgress() {
        let total = task.phrases.count
        let listened = listenedPhrases.count
        if listened >= total {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "还剩 \(total - listened) 个词组未听"
        }
    }
}

struct PhraseCard: View {
    let phrase: PhraseItem
    let index: Int
    let accentColor: Color
    var onListen: (() -> Void)? = nil

    @State private var exampleVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: accentColor.opacity(0.25), radius: 3, x: 0, y: 1)
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(phrase.phrase)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    if let meaning = phrase.meaning {
                        Text(meaning)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondText)
                    }
                }

                Spacer()

                Button {
                    WordPronouncer.shared.speak(phrase.phrase, locale: "en-US", rate: 0.46, sourceLabel: "Phrase")
                    onListen?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 38, height: 38)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(accentColor)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    exampleVisible.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: exampleVisible ? "eye.fill" : "eye.slash")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(exampleVisible ? 0 : -10))
                        Text(exampleVisible ? "Example" : "Tap to see example")
                            .font(.caption.bold())
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .rotationEffect(.degrees(exampleVisible ? 180 : 0))
                    }
                    .foregroundStyle(accentColor.opacity(0.7))

                    if let sourceBand = phrase.sourceBand {
                        Text(sourceBand)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.5))
                            .clipShape(Capsule())
                    }

                    if exampleVisible {
                        if !phrase.example.isEmpty {
                            Text(phrase.example)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .italic()
                                .lineSpacing(4)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                    removal: .opacity
                                ))

                            HStack(spacing: 8) {
                                InlineAudioPlayerControl(
                                    text: phrase.example,
                                    playbackID: EnglishSpeechPlayer.playbackID(for: phrase.example, category: "phrase-ex"),
                                    sourceLabel: "Phrase Example",
                                    accentColor: accentColor,
                                    style: .compact
                                )
                                TranslateButton(englishText: phrase.example, accentColor: accentColor)
                            }
                            .transition(.opacity)
                        }

                        if let nativeNote = phrase.nativeNote {
                            Text(nativeNote)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                                .lineSpacing(2)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(accentColor.opacity(exampleVisible ? 0.06 : 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 18, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 18
            )
            .fill(
                LinearGradient(
                    colors: [accentColor.opacity(0.4), accentColor.opacity(0.1)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 3)
        }
        .shadow(color: accentColor.opacity(0.08), radius: 10, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Framework Step
struct FrameworkStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedSentences: Set<Int> = []
    private let labels = ["开场", "来源", "使用", "例子", "收尾"]
    private var lesson: LessonContent? { task.lessonContent }

    private var totalSentences: Int { task.frameworkSentences.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "表达框架",
                    subtitle: "先看总结构，再补连接表达和升级表达。",
                    accentColor: Color(hex: "8B5CF6")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "rectangle.3.group.fill",
                    title: "表达框架",
                    english: "Expression Framework",
                    subtitle: "掌握答题模板，让表达有条理",
                    accentColor: Color(hex: "8B5CF6"),
                    secondaryColor: Color(hex: "A78BFA")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            if let lesson {
                lessonFrameworkContent(lesson)
            } else {
                standardFrameworkContent
            }
        }
        .onAppear {
            appeared = true
            updateFrameworkProgress()
        }
        .onChange(of: listenedSentences.count) { _, _ in
            updateFrameworkProgress()
        }
    }

    private func updateFrameworkProgress() {
        if totalSentences == 0 {
            canComplete = true
            progressHint = nil
            return
        }
        let remaining = totalSentences - listenedSentences.count
        if remaining <= 0 {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "还剩 \(remaining) 个框架句子未听"
        }
    }

    private let frameworkColor = Color(hex: "8B5CF6")

    private var standardFrameworkContent: some View {
        Group {
            GradientAccentCard(color: frameworkColor, spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(task.frameworkSentences.enumerated()), id: \.offset) { index, sentence in
                        FrameworkSentenceCard(
                            index: index + 1,
                            label: index < labels.count ? labels[index] : "要点",
                            sentence: sentence,
                            accentColor: frameworkColor,
                            isLast: index == task.frameworkSentences.count - 1,
                            onListen: { listenedSentences.insert(index) }
                        )
                    }
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            if !task.upgradeExpressions.isEmpty {
                GradientAccentCard(color: Color(hex: "F59E0B")) {
                    StepSectionLabel(
                        icon: "arrow.up.circle.fill",
                        title: "升级表达",
                        color: Color(hex: "F59E0B")
                    )

                    ForEach(Array(task.upgradeExpressions.enumerated()), id: \.offset) { _, pair in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("Before")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(AppColors.tertiaryText)
                                    .clipShape(Capsule())
                                Text(pair.original)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.tertiaryText)
                                    .strikethrough(color: AppColors.tertiaryText.opacity(0.5))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "EF4444").opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("After")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(AppColors.success)
                                        .clipShape(Capsule())
                                    Text(pair.upgraded)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                HStack(spacing: 8) {
                                    InlineAudioPlayerControl(
                                        text: pair.upgraded,
                                        playbackID: EnglishSpeechPlayer.playbackID(for: pair.upgraded, category: "fw-upgrade"),
                                        sourceLabel: "Upgrade",
                                        accentColor: Color(hex: "F59E0B"),
                                        style: .compact
                                    )
                                    TranslateButton(englishText: pair.upgraded, accentColor: Color(hex: "F59E0B"))
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.success.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(12)
                        .background(AppColors.surface.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .staggerIn(index: 2, appeared: appeared)
            }
        }
    }

    private func lessonFrameworkContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GradientAccentCard(color: frameworkColor, spacing: 16) {
                StepSectionLabel(
                    icon: "rectangle.3.group.fill",
                    title: "Framework Goal",
                    color: frameworkColor
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.framework.goal)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)

                    InlineAudioPlayerControl(
                        text: lesson.framework.goal,
                        playbackID: EnglishSpeechPlayer.playbackID(for: lesson.framework.goal, category: "fw-goal"),
                        sourceLabel: "Framework Goal",
                        accentColor: frameworkColor,
                        style: .compact
                    )
                    TranslateButton(englishText: lesson.framework.goal, accentColor: frameworkColor)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(frameworkColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                ForEach(lesson.framework.defaultStructure, id: \.section) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.section)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(frameworkColor.opacity(0.7))
                            .clipShape(Capsule())

                        ForEach(section.moves, id: \.self) { move in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(frameworkColor)
                                        .padding(.top, 3)
                                    Text(move)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(2)
                                }
                                TranslateButton(englishText: move, accentColor: frameworkColor)
                                    .padding(.leading, 22)
                            }
                        }
                    }
                    .padding(14)
                    .background(AppColors.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            GradientAccentCard(color: Color(hex: "5B6EF5")) {
                StepSectionLabel(
                    icon: "text.quote",
                    title: "Delivery Markers",
                    color: Color(hex: "5B6EF5")
                )

                lessonMarkersContent(lesson.framework.deliveryMarkers)
            }
            .staggerIn(index: 2, appeared: appeared)
        }
    }

    private func frameworkSection(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(accentColor)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func labelLine(tag: String, text: String, tint: Color, strike: Bool) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tint)
                .clipShape(Capsule())
            Text(text)
                .font(.caption)
                .foregroundStyle(strike ? AppColors.tertiaryText : AppColors.primaryText)
                .strikethrough(strike)
        }
    }

    private func lessonMarkersContent(_ markers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(markers, id: \.self) { marker in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "5B6EF5"))
                            .padding(.top, 3)
                        Text(marker)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 8) {
                        InlineAudioPlayerControl(
                            text: marker,
                            playbackID: EnglishSpeechPlayer.playbackID(for: marker, category: "fw-marker"),
                            sourceLabel: "Delivery Marker",
                            accentColor: Color(hex: "5B6EF5"),
                            style: .compact
                        )
                        TranslateButton(englishText: marker, accentColor: Color(hex: "5B6EF5"))
                    }
                    .padding(.leading, 21)
                }
            }
        }
    }
}

struct FrameworkSentenceCard: View {
    let index: Int
    let label: String
    let sentence: String
    let accentColor: Color
    let isLast: Bool
    var onListen: (() -> Void)? = nil

    private var playbackId: String {
        EnglishSpeechPlayer.playbackID(for: sentence, category: "framework")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: accentColor.opacity(0.25), radius: 4, x: 0, y: 2)
                    Text("\(index)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.2), accentColor.opacity(0.08)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(label)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(accentColor)
                        .tracking(0.5)
                    Spacer()
                    Button {
                        WordPronouncer.shared.speak(sentence, locale: "en-US", rate: 0.46, sourceLabel: "Framework")
                        onListen?()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)
                            .frame(width: 28, height: 28)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                highlightedSentence(sentence)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                TranslateButton(englishText: sentence, accentColor: accentColor)
            }
            .padding(.vertical, 3)
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    // Highlight `...` parts as fill-in blanks
    @ViewBuilder
    private func highlightedSentence(_ text: String) -> some View {
        let parts = text.components(separatedBy: "...")
        if parts.count > 1 {
            // Has fill-in blanks
            Text(buildAttributedSentence(text))
        } else {
            Text(text)
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private func buildAttributedSentence(_ text: String) -> AttributedString {
        var result = AttributedString()
        let segments = text.components(separatedBy: "...")

        for (i, segment) in segments.enumerated() {
            var part = AttributedString(segment)
            part.foregroundColor = AppColors.primaryText
            result.append(part)

            if i < segments.count - 1 {
                var blank = AttributedString("  ___  ")
                blank.foregroundColor = accentColor
                blank.font = .system(size: 15, weight: .bold, design: .rounded)
                result.append(blank)
            }
        }
        return result
    }
}

// MARK: - Samples Step
struct SamplesStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var selectedBand = 0
    @State private var appeared = false
    @State private var listenedBands: Set<Int> = []
    private var hasLessonContent: Bool { task.lessonContent != nil }
    private var lesson: LessonContent? { task.lessonContent }

    private var bandColors: [Color] {
        [Color(hex: "4A90D9"), Color(hex: "F59E0B"), Color(hex: "EF4444")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "范文学习",
                    subtitle: "用 Band 6 / 7 / 8 对照看内容深度和表达差异。",
                    accentColor: Color(hex: "EC4899")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "doc.richtext.fill",
                    title: "范文学习",
                    english: "Sample Answers",
                    subtitle: "三个水平的示范回答，对比学习",
                    accentColor: Color(hex: "EC4899"),
                    secondaryColor: Color(hex: "F472B6")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Band selector — enhanced pill tabs
            HStack(spacing: 6) {
                ForEach(Array(task.sampleAnswers.enumerated()), id: \.offset) { index, sample in
                    let isSelected = selectedBand == index
                    Button {
                        withAnimation(.spring(duration: 0.3)) { selectedBand = index }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isSelected ? .white.opacity(0.3) : bandColors[index].opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(sample.band)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? .white : bandColors[index])
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [bandColors[index], bandColors[index].opacity(0.78)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(bandColors[index].opacity(0.08))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(bandColors[index].opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? bandColors[index].opacity(0.25) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            if selectedBand < task.sampleAnswers.count, let bandGuide = task.sampleAnswers[selectedBand].bandGuide {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        StepSectionLabel(
                            icon: "list.bullet.rectangle.portrait",
                            title: "Band \(bandGuide.band) 表达框架",
                            color: bandColors[selectedBand]
                        )
                        Spacer()
                        Text(bandGuide.focus)
                            .font(.caption.bold())
                            .foregroundStyle(bandColors[selectedBand])
                    }

                    frameworkGuideSection(
                        title: "Opening",
                        lines: bandGuide.opening,
                        tint: bandColors[selectedBand]
                    )
                    frameworkGuideSection(
                        title: "Body",
                        lines: bandGuide.body,
                        tint: bandColors[selectedBand]
                    )
                    frameworkGuideSection(
                        title: "Closing",
                        lines: bandGuide.closing,
                        tint: bandColors[selectedBand]
                    )
                }
                .padding(18)
                .cardStyle()
                .staggerIn(index: 2, appeared: appeared)
            }

            // Sample content
            if selectedBand < task.sampleAnswers.count {
                let sample = task.sampleAnswers[selectedBand]
                let bandColor = bandColors[selectedBand]

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(sample.band)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(bandColor)
                            .clipShape(Capsule())
                        Spacer()
                        Text("\(sample.wordCount) words")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.tertiaryText)
                    }

                    // Highlighted sample content
                    highlightedSampleText(sample.content)
                        .lineSpacing(6)

                    InlineAudioPlayerControl(
                        text: sample.content,
                        playbackID: EnglishSpeechPlayer.playbackID(for: sample.content, category: "sample-\(selectedBand)"),
                        sourceLabel: "Sample Answer",
                        accentColor: bandColor,
                        title: "Listen to Pronunciation",
                        onPlay: { listenedBands.insert(selectedBand) }
                    )

                    TranslateButton(englishText: sample.content, accentColor: bandColor)

                    if !sample.nativeFeatures.isEmpty {
                        Divider().background(AppColors.border)

                        VStack(alignment: .leading, spacing: 8) {
                            StepSectionLabel(icon: "sparkles", title: "Native Features", color: bandColor)

                            ForEach(sample.nativeFeatures, id: \.self) { feature in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(bandColor)
                                            .padding(.top, 4)
                                        Text(feature)
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.secondText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    TranslateButton(englishText: feature, accentColor: bandColor)
                                        .padding(.leading, 17)
                                }
                            }
                        }
                    }

                    if !sample.upgrades.isEmpty {
                        Divider().background(AppColors.border)

                        VStack(alignment: .leading, spacing: 10) {
                            StepSectionLabel(icon: "arrow.up.circle.fill", title: "Expression Upgrades", color: bandColor)

                            ForEach(Array(sample.upgrades.enumerated()), id: \.offset) { _, item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("Original")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(hex: "EF4444"))
                                        Text(item.original)
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.tertiaryText)
                                            .strikethrough(color: Color(hex: "EF4444").opacity(0.4))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("Improved")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .foregroundStyle(bandColor)
                                            Text(item.improved)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(AppColors.primaryText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        HStack(spacing: 8) {
                                            InlineAudioPlayerControl(
                                                text: item.improved,
                                                playbackID: EnglishSpeechPlayer.playbackID(for: item.improved, category: "sample-upgrade"),
                                                sourceLabel: "Sample Upgrade",
                                                accentColor: bandColor,
                                                style: .compact
                                            )
                                            TranslateButton(englishText: item.improved, accentColor: bandColor)
                                        }
                                    }

                                    Text(item.why)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if !item.note.isEmpty {
                                        Text(item.note)
                                            .font(.caption)
                                            .foregroundStyle(AppColors.tertiaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                if item.original != sample.upgrades.last?.original {
                                    Divider().background(AppColors.border.opacity(0.5))
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .cardStyle()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .staggerIn(index: lesson == nil ? 2 : 3, appeared: appeared)
            }
        }
        .onAppear {
            appeared = true
            progressHint = "听完至少 1 个 Band 的范文音频"
        }
        .onChange(of: listenedBands.count) { _, _ in
            if !listenedBands.isEmpty {
                canComplete = true
                progressHint = nil
            }
        }
    }

    private func frameworkGuideSection(title: String, lines: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(tint)

            ForEach(lines, id: \.self) { line in
                VStack(alignment: .leading, spacing: 6) {
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                    TranslateButton(englishText: line, accentColor: tint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(tint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Highlight vocabulary words from this task in the sample text
    @ViewBuilder
    private func highlightedSampleText(_ content: String) -> some View {
        let vocabWords = Set(task.vocabulary.map { $0.word.lowercased() })
        let words = content.components(separatedBy: " ")

        Text(words.reduce(AttributedString()) { result, word in
            var r = result
            if !r.characters.isEmpty {
                r.append(AttributedString(" "))
            }
            let cleaned = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if vocabWords.contains(cleaned) {
                var attr = AttributedString(word)
                attr.foregroundColor = accentColor
                attr.font = .subheadline.bold()
                attr.underlineStyle = .single
                r.append(attr)
            } else {
                var attr = AttributedString(word)
                attr.foregroundColor = AppColors.primaryText
                attr.font = .subheadline
                r.append(attr)
            }
            return r
        })
    }

}

// MARK: - Practice Prompt
private enum PracticeInputMode: String, CaseIterable, Identifiable {
    case text = "文字输入"
    case voice = "语音输入"

    var id: String { rawValue }
}

private enum PracticeLanguageMode: String, CaseIterable, Identifiable {
    case native = "母语输入"
    case english = "英文草稿"

    var id: String { rawValue }
}

struct PracticePromptView: View {
    let stageId: Int
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?
    private let labels = ["开场", "来源", "使用", "例子", "收尾"]
    private var lesson: LessonContent? { task.lessonContent }

    @StateObject private var speechInput = SpeechInputManager()
    @State private var inputMode: PracticeInputMode = .text
    @State private var languageMode: PracticeLanguageMode = .native
    @State private var draftInput: String
    @State private var translatedEnglish: String
    @State private var polishedEnglish: String
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var listenedResultAudio = false
    @FocusState private var isInputFocused: Bool

    init(stageId: Int, task: SpeakingTask, accentColor: Color, canComplete: Binding<Bool>, progressHint: Binding<String?>) {
        self.stageId = stageId
        self.task = task
        self.accentColor = accentColor
        self._canComplete = canComplete
        self._progressHint = progressHint

        let defaults = UserDefaults.standard
        let base = "practice_s\(stageId)_t\(task.id)"
        _draftInput = State(initialValue: defaults.string(forKey: "\(base)_draft") ?? "")
        _translatedEnglish = State(initialValue: defaults.string(forKey: "\(base)_translated") ?? "")
        _polishedEnglish = State(initialValue: defaults.string(forKey: "\(base)_polished") ?? "")
    }

    private var baseKey: String {
        "practice_s\(stageId)_t\(task.id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "口语练习",
                    subtitle: "按提示把内容真正说出来，不要只停留在阅读。",
                    accentColor: Color(hex: "EF4444")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "mic.fill",
                    title: "口语练习",
                    english: "Speaking Practice",
                    subtitle: "实战演练，开口说英语",
                    accentColor: Color(hex: "EF4444"),
                    secondaryColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            topicCard
                .staggerIn(index: 1, appeared: appeared)
            if let lesson {
                practiceChecklistCard(lesson)
                    .staggerIn(index: 2, appeared: appeared)
            }
            frameworkHints
                .staggerIn(index: 3, appeared: appeared)
            inputCard
                .staggerIn(index: 4, appeared: appeared)
            actionArea
                .staggerIn(index: 5, appeared: appeared)

            if !translatedEnglish.isEmpty {
                resultCard(
                    title: languageMode == .native ? "英文结果（API）" : "当前英文草稿",
                    subtitle: languageMode == .native ? "基于当前后端 contract 的翻译结果" : "当前后端没有额外润色接口，保留你的英文输入",
                    text: translatedEnglish,
                    tint: Color(hex: "4A90D9")
                )
            }

            if !polishedEnglish.isEmpty {
                resultCard(
                    title: "保留字段",
                    subtitle: "等待后端补充 DailySpeak 专用润色接口后再恢复",
                    text: polishedEnglish,
                    tint: Color(hex: "10B981")
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "DC2626"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "FEE2E2"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .onChange(of: draftInput) { _, newValue in
            save(newValue, key: "\(baseKey)_draft")
        }
        .onChange(of: translatedEnglish) { _, newValue in
            save(newValue, key: "\(baseKey)_translated")
        }
        .onChange(of: polishedEnglish) { _, newValue in
            save(newValue, key: "\(baseKey)_polished")
        }
        .onChange(of: speechInput.transcript) { _, transcript in
            guard !transcript.isEmpty else { return }
            draftInput = transcript
            save(transcript, key: "\(baseKey)_voice")
        }
        .onDisappear {
            speechInput.stopRecording()
        }
        .onAppear {
            appeared = true
            updatePracticeProgress()
        }
        .onChange(of: translatedEnglish) { _, _ in
            updatePracticeProgress()
        }
        .onChange(of: listenedResultAudio) { _, _ in
            updatePracticeProgress()
        }
    }

    private func updatePracticeProgress() {
        let hasTranslation = !translatedEnglish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasTranslation && listenedResultAudio {
            canComplete = true
            progressHint = nil
        } else if hasTranslation {
            canComplete = false
            progressHint = "听完英文翻译语音以继续"
        } else {
            canComplete = false
            progressHint = "提交你的回答并获取翻译结果"
        }
    }

    private let practiceColor = Color(hex: "EF4444")

    private var topicCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(practiceColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("TOPIC")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(practiceColor)
                    .tracking(1.2)
                Spacer()
                if let lesson {
                    Text(lesson.practice.targetLength)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(practiceColor.opacity(0.7))
                        .clipShape(Capsule())
                }
            }
            if let lesson {
                Text(lesson.practice.task)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            Text(task.prompt)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .italic()
                .lineSpacing(4)

            TranslateButton(englishText: task.prompt, accentColor: practiceColor)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                AppColors.card
                LinearGradient(
                    colors: [practiceColor.opacity(0.06), practiceColor.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(practiceColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: practiceColor.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private func practiceChecklistCard(_ lesson: LessonContent) -> some View {
        GradientAccentCard(color: practiceColor, spacing: 14) {
            StepSectionLabel(icon: "checklist.checked", title: "Speaking Checklist", color: practiceColor)

            ForEach(lesson.practice.checklist, id: \.self) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(practiceColor)
                            .padding(.top, 2)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }

                    HStack(spacing: 8) {
                        InlineAudioPlayerControl(
                            text: item,
                            playbackID: EnglishSpeechPlayer.playbackID(for: item, category: "checklist"),
                            sourceLabel: "Checklist",
                            accentColor: practiceColor,
                            style: .compact
                        )
                        TranslateButton(englishText: item, accentColor: practiceColor)
                    }
                }
                .padding(10)
                .background(practiceColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.border.opacity(0.3), AppColors.border, AppColors.border.opacity(0.3)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)

            StepSectionLabel(icon: "text.bubble.fill", title: "Self Prompts", color: practiceColor)

            ForEach(lesson.practice.selfPrompts, id: \.self) { prompt in
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt)
                        .font(.caption.bold())
                        .foregroundStyle(practiceColor)

                    HStack(spacing: 8) {
                        InlineAudioPlayerControl(
                            text: prompt,
                            playbackID: EnglishSpeechPlayer.playbackID(for: prompt, category: "selfprompt"),
                            sourceLabel: "Self Prompt",
                            accentColor: practiceColor,
                            style: .compact
                        )
                        TranslateButton(englishText: prompt, accentColor: practiceColor)
                    }
                }
                .padding(10)
                .background(practiceColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var frameworkHints: some View {
        GradientAccentCard(color: Color(hex: "8B5CF6"), spacing: 12) {
            StepSectionLabel(
                icon: "list.bullet.rectangle.portrait",
                title: "表达框架提示",
                color: Color(hex: "8B5CF6")
            )

            ForEach(Array(task.frameworkSentences.enumerated()), id: \.offset) { index, sentence in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Text(index < labels.count ? labels[index] : "要点")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "8B5CF6").opacity(0.6))
                            .clipShape(Capsule())

                        Text(sentence)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }

                    HStack(spacing: 8) {
                        InlineAudioPlayerControl(
                            text: sentence,
                            playbackID: EnglishSpeechPlayer.playbackID(for: sentence, category: "fwhint"),
                            sourceLabel: "Framework Hint",
                            accentColor: Color(hex: "8B5CF6"),
                            style: .compact
                        )
                        TranslateButton(englishText: sentence, accentColor: Color(hex: "8B5CF6"))
                    }
                }
            }
        }
    }

    private var inputCard: some View {
        GradientAccentCard(color: Color(hex: "4A90D9"), spacing: 14) {
            StepSectionLabel(icon: "square.and.pencil", title: "输入你的回答草稿", color: Color(hex: "4A90D9"))

            modeSelector(
                title: "输入方式",
                items: PracticeInputMode.allCases,
                selected: inputMode
            ) { inputMode = $0 }

            if inputMode == .text {
                modeSelector(
                    title: "内容类型",
                    items: PracticeLanguageMode.allCases,
                    selected: languageMode
                ) { languageMode = $0 }
            }

            if inputMode == .voice {
                voiceTools
            }

            draftEditor

            if let speechError = speechInput.lastError {
                Text(speechError)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "DC2626"))
            }

            Text("草稿会自动保存。你可以先用母语输入，再通过当前后端接口转成英文。")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
                .lineSpacing(2)
        }
    }

    private var voiceTools: some View {
        HStack(spacing: 10) {
            Button {
                Task { await speechInput.toggleRecording() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechInput.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(speechInput.isRecording ? "停止录音" : "开始录音")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(speechInput.isRecording ? Color(hex: "DC2626") : accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if speechInput.isRecording {
                Text("识别中...")
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var draftEditor: some View {
        TextEditor(text: $draftInput)
            .focused($isInputFocused)
            .frame(minHeight: 120)
            .padding(10)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isInputFocused ? accentColor : AppColors.border, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if draftInput.isEmpty {
                    Text(languageMode == .native ? "先输入母语内容，建议 4-6 句..." : "先写英文草稿，当前会保留你的原文...")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
    }

    private var actionArea: some View {
        Button {
            runPipeline()
        } label: {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.subheadline.bold())
                }
                Text(languageMode == .native ? "母语 -> 英文" : "保留英文草稿")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing
                    ? AnyShapeStyle(AppColors.border)
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [practiceColor, practiceColor.opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(
                color: draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? .clear
                    : practiceColor.opacity(0.3),
                radius: 10, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
    }

    private func resultCard(title: String, subtitle: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            StepSectionLabel(icon: "text.bubble.fill", title: title, color: tint)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)

            InlineAudioPlayerControl(
                text: text,
                playbackID: EnglishSpeechPlayer.playbackID(for: text, category: "practice"),
                sourceLabel: "Practice Result",
                accentColor: tint,
                title: "听英文发音",
                onPlay: {
                    listenedResultAudio = true
                }
            )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(5)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TranslateButton(englishText: text, accentColor: tint)
        }
        .padding(18)
        .cardStyle()
    }

    private func modeSelector<Item: Identifiable>(
        title: String,
        items: [Item],
        selected: Item,
        onSelect: @escaping (Item) -> Void
    ) -> some View where Item: RawRepresentable, Item.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppColors.tertiaryText)

            HStack(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = item.id == selected.id
                    Button {
                        withAnimation(.spring(duration: 0.24)) {
                            onSelect(item)
                        }
                    } label: {
                        Text(item.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(isSelected ? .white : AppColors.secondText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(isSelected ? accentColor : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func runPipeline() {
        let source = draftInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        isInputFocused = false

        Task {
            do {
                let translated: String
                if languageMode == .native {
                    translated = try await PracticeAIService.shared.translateToEnglish(
                        nativeText: source,
                        topic: task.prompt
                    )
                } else {
                    translated = source
                }

                translatedEnglish = translated
                polishedEnglish = ""
                isProcessing = false
            } catch {
                isProcessing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save(_ value: String, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
