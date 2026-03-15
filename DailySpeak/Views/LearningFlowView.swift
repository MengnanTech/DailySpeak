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
                                ? "Complete this step"
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
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(english)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    }

                    CompactPlayButton(
                        text: subtitle,
                        playbackID: EnglishSpeechPlayer.playbackID(for: subtitle, category: "step-header"),
                        sourceLabel: english,
                        accentColor: .white,
                        onPlay: {}
                    )
                }
            }
            .padding(20)
        }
        .frame(height: 130)
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
    let englishTitle: String
    let englishSubtitle: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(accentColor)
                    .tracking(1.3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.08))
                    .clipShape(Capsule())

                Spacer()

                HStack(spacing: 6) {
                    CompactPlayButton(
                        text: englishSubtitle,
                        playbackID: EnglishSpeechPlayer.playbackID(for: englishSubtitle, category: "lesson-header"),
                        sourceLabel: englishTitle,
                        accentColor: accentColor
                    )
                    TranslateButton(englishText: englishSubtitle, accentColor: accentColor, showInline: false)
                }
            }

            Text(englishTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)

            Text(englishSubtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)

            TranslationOverlay(englishText: englishSubtitle, accentColor: accentColor)

            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.tertiaryText)
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
    @State private var showKeyPointsGuide = false
    @State private var showSequenceGuide = false
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
            let allSeqText = lesson.strategy.sequence.map { "\($0.phase). \($0.focus). \($0.target)" }.joined(separator: " ")
            ids.insert(EnglishSpeechPlayer.playbackID(for: allSeqText, category: "sequence-all"))
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
            if let lesson {
                let promptText = task.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                let goalText = (lesson.topic.learningGoal ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let headerText = goalText.isEmpty ? promptText : (promptText + " " + goalText)
                let headerPlaybackId = EnglishSpeechPlayer.playbackID(for: headerText, category: "strategy-header")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center) {
                        Text((task.lessonContent?.topic.stageLabel ?? "Structured Lesson").uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(stepColor)
                            .tracking(1.3)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(stepColor.opacity(0.08))
                            .clipShape(Capsule())

                        Spacer()

                        HStack(spacing: 8) {
                            CompactPlayButton(
                                text: headerText,
                                playbackID: headerPlaybackId,
                                sourceLabel: "Strategy Header",
                                accentColor: stepColor
                            )
                            TranslateButton(englishText: headerText, accentColor: stepColor, showInline: false)
                        }
                    }

                    Text("Answer Strategy")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text(promptText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)

                    if !goalText.isEmpty {
                        Text(goalText)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                            .padding(.top, 2)
                    }

                    TranslationOverlay(englishText: headerText, accentColor: stepColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "lightbulb.max.fill",
                    title: "答题策略",
                    english: "Strategy & Tips",
                    subtitle: "Learn to organize answers and master response flow",
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
        .fullScreenCover(isPresented: $showKeyPointsGuide) {
            if let lesson {
                KeyPointsGuidedView(
                    angles: lesson.strategy.angles,
                    accentColor: stepColor,
                    onComplete: { completedIds in
                        listenedAudioIds.formUnion(completedIds)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showSequenceGuide) {
            if let lesson {
                SequenceGuidedView(
                    steps: lesson.strategy.sequence,
                    accentColor: stepColor,
                    onComplete: { completedId in
                        listenedAudioIds.insert(completedId)
                    }
                )
            }
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
                StepSectionLabel(icon: "lightbulb.fill", title: "Response Tips", color: stepColor)

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
                StepSectionLabel(icon: "target", title: "Scoring Criteria", color: Color(hex: "EF4444"))

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
            // Section: angles
            HStack {
                Text("\(lesson.strategy.angles.count) Key Points")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(stepColor)
                Spacer()

                Button {
                    showKeyPointsGuide = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Guide")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(stepColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .staggerIn(index: 2, appeared: appeared)

            ForEach(Array(lesson.strategy.angles.enumerated()), id: \.offset) { index, angle in
                let angleText = angle.title + ". " + angle.content.joined(separator: ". ")
                let anglePlaybackId = EnglishSpeechPlayer.playbackID(for: angleText, category: "angle")

                VStack(alignment: .leading, spacing: 12) {
                    // Header: number + title + buttons right-aligned
                    HStack(alignment: .center, spacing: 0) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(stepColor)
                            .clipShape(Circle())
                            .padding(.trailing, 10)

                        Text(angle.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.primaryText)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        HStack(spacing: 8) {
                            CompactPlayButton(
                                text: angleText,
                                playbackID: anglePlaybackId,
                                sourceLabel: "Strategy Angle",
                                accentColor: stepColor,
                                onPlay: { listenedAudioIds.insert(anglePlaybackId) }
                            )
                            TranslateButton(englishText: angleText, accentColor: stepColor, showInline: false)
                        }
                        .layoutPriority(1)
                    }

                    // Content items
                    ForEach(angle.content, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(stepColor.opacity(0.4))
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(item)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }

                    TranslationOverlay(englishText: angleText, accentColor: stepColor)
                }
                .padding(14)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                        .foregroundStyle(stepColor.opacity(0.3))
                )
                .staggerIn(index: index + 3, appeared: appeared)
            }

            // Sequence — one unified card
            let allSeqText = lesson.strategy.sequence.map { "\($0.phase). \($0.focus). \($0.target)" }.joined(separator: " ")
            let allSeqPlaybackId = EnglishSpeechPlayer.playbackID(for: allSeqText, category: "sequence-all")

            // Section header — outside the card, matching Key Points style
            HStack {
                Text("Speaking Order")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(stepColor)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        showSequenceGuide = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text("Guide")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .fixedSize()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(stepColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    CompactPlayButton(
                        text: allSeqText,
                        playbackID: allSeqPlaybackId,
                        sourceLabel: "Strategy Sequence",
                        accentColor: stepColor,
                        onPlay: { listenedAudioIds.insert(allSeqPlaybackId) }
                    )
                    TranslateButton(englishText: allSeqText, accentColor: stepColor, showInline: false)
                }
            }
            .staggerIn(index: lesson.strategy.angles.count + 3, appeared: appeared)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(lesson.strategy.sequence.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        // Timeline
                        VStack(spacing: 0) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(stepColor)
                                .clipShape(Circle())
                            if index < lesson.strategy.sequence.count - 1 {
                                Rectangle()
                                    .fill(stepColor.opacity(0.15))
                                    .frame(width: 1.5)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
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
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, index < lesson.strategy.sequence.count - 1 ? 8 : 0)
                    }
                }

                TranslationOverlay(englishText: allSeqText, accentColor: stepColor)
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(stepColor.opacity(0.3))
            )
            .staggerIn(index: lesson.strategy.angles.count + 4, appeared: appeared)

            // Content Distribution
            let ratioText = lesson.strategy.contentRatio.map { "\($0.label): \($0.value)" }.joined(separator: ". ")
            let ratioPlaybackId = EnglishSpeechPlayer.playbackID(for: ratioText, category: "content-dist")

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text("Content Distribution")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(stepColor)
                    Spacer()
                    HStack(spacing: 8) {
                        CompactPlayButton(
                            text: ratioText,
                            playbackID: ratioPlaybackId,
                            sourceLabel: "Content Distribution",
                            accentColor: stepColor
                        )
                        TranslateButton(englishText: ratioText, accentColor: stepColor, showInline: false)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(lesson.strategy.contentRatio, id: \.label) { ratio in
                        VStack(spacing: 4) {
                            Text(ratio.value)
                                .font(.caption.bold())
                                .foregroundStyle(stepColor)
                            Text(ratio.label)
                                .font(.caption2)
                                .foregroundStyle(AppColors.secondText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(stepColor.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                TranslationOverlay(englishText: ratioText, accentColor: stepColor)
            }
            .staggerIn(index: lesson.strategy.angles.count + 5, appeared: appeared)
        }
    }
}

// MARK: - Key Points Guided View (Immersive)
private struct KeyPointsGuidedView: View {
    let angles: [LessonContent.Strategy.Angle]
    let accentColor: Color
    var onComplete: (Set<String>) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var cardAppeared = false
    @State private var audioFinished = false
    @State private var completedAudioIds: Set<String> = []
    @State private var allDone = false

    private func angleText(for angle: LessonContent.Strategy.Angle) -> String {
        angle.title + ". " + angle.content.joined(separator: ". ")
    }

    private func playbackID(for angle: LessonContent.Strategy.Angle) -> String {
        EnglishSpeechPlayer.playbackID(for: angleText(for: angle), category: "angle")
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { } // block taps through

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        player.stopPlayback()
                        onComplete(completedAudioIds)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Progress indicator
                    Text("\(currentIndex + 1) / \(angles.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(angles.count), height: 4)
                            .animation(.spring(duration: 0.5), value: currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Card
                if !allDone {
                    let angle = angles[currentIndex]
                    let text = angleText(for: angle)
                    let pid = playbackID(for: angle)

                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack(spacing: 10) {
                            Text("\(currentIndex + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(angle.title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()
                        }

                        // Content items
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(angle.content, id: \.self) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(accentColor.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 8)
                                    Text(item)
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(4)
                                }
                            }
                        }

                        // Audio player
                        HStack(spacing: 12) {
                            CompactPlayButton(
                                text: text,
                                playbackID: pid,
                                sourceLabel: "Guided Angle",
                                accentColor: accentColor
                            )

                            if player.isPlaying(id: pid) || player.isPaused(id: pid) {
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor.opacity(0.15))
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor)
                                            .frame(width: geo.size.width * player.progress, height: 4)
                                    }
                                }
                                .frame(height: 4)
                                .transition(.opacity)
                            }

                            Spacer()

                            TranslateButton(englishText: text, accentColor: accentColor, showInline: false)
                        }

                        TranslationOverlay(englishText: text, accentColor: accentColor)

                        // Confirmation button — shown after audio finishes
                        if audioFinished {
                            Button {
                                advanceToNext()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: currentIndex < angles.count - 1 ? "checkmark" : "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(currentIndex < angles.count - 1 ? "Got it, next" : "All Done")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(24)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex) // force re-create for transition
                    .onAppear {
                        cardAppeared = true
                        audioFinished = false
                        // Auto-play after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let angle = angles[currentIndex]
                            let text = angleText(for: angle)
                            let pid = playbackID(for: angle)
                            if !player.isPlaying(id: pid) {
                                player.togglePlayback(id: pid, text: text, sourceLabel: "Guided Angle")
                            }
                        }
                        // Fallback: ensure button appears even if audio fails
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !audioFinished { withAnimation { audioFinished = true } }
                        }
                    }
                } else {
                    // All done celebration
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentColor)

                        Text("All Key Points Learned!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Continue to the next section")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete(completedAudioIds)
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: currentIndex)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: audioFinished)
        .animation(.spring(duration: 0.4), value: allDone)
        .onChange(of: player.activePlaybackID) { oldValue, newValue in
            // Detect when current angle's audio finishes playing
            let currentPid = playbackID(for: angles[currentIndex])
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                // Audio finished naturally
                withAnimation {
                    audioFinished = true
                }
                completedAudioIds.insert(currentPid)
            }
        }
        .background(ClearBackgroundView())
    }

    private func advanceToNext() {
        let currentPid = playbackID(for: angles[currentIndex])
        completedAudioIds.insert(currentPid)

        if currentIndex < angles.count - 1 {
            withAnimation {
                currentIndex += 1
                audioFinished = false
            }
        } else {
            withAnimation {
                allDone = true
            }
        }
    }
}

// Helper to make fullScreenCover background transparent
private struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Speaking Order Guided View (Immersive)
private struct SequenceGuidedView: View {
    let steps: [LessonContent.Strategy.SequenceStep]
    let accentColor: Color
    var onComplete: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var audioFinished = false
    @State private var allDone = false

    private func stepText(for step: LessonContent.Strategy.SequenceStep) -> String {
        "\(step.phase). \(step.focus). \(step.target)"
    }

    private func stepPlaybackID(for step: LessonContent.Strategy.SequenceStep) -> String {
        EnglishSpeechPlayer.playbackID(for: stepText(for: step), category: "seq-step")
    }

    private var allStepsText: String {
        steps.map { "\($0.phase). \($0.focus). \($0.target)" }.joined(separator: " ")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        player.stopPlayback()
                        onComplete(EnglishSpeechPlayer.playbackID(for: allStepsText, category: "sequence-all"))
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(currentIndex + 1) / \(steps.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(steps.count), height: 4)
                            .animation(.spring(duration: 0.5), value: currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if !allDone {
                    let step = steps[currentIndex]
                    let text = stepText(for: step)
                    let pid = stepPlaybackID(for: step)

                    VStack(alignment: .leading, spacing: 16) {
                        // Step number + phase
                        HStack(spacing: 10) {
                            Text("\(currentIndex + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(step.phase)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()
                        }

                        // Focus tag
                        Text(step.focus)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())

                        // Target
                        Text(step.target)
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)

                        // Audio + translate
                        HStack(spacing: 12) {
                            CompactPlayButton(
                                text: text,
                                playbackID: pid,
                                sourceLabel: "Guided Sequence",
                                accentColor: accentColor
                            )

                            if player.isPlaying(id: pid) || player.isPaused(id: pid) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor.opacity(0.15))
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor)
                                            .frame(width: geo.size.width * player.progress, height: 4)
                                    }
                                }
                                .frame(height: 4)
                                .transition(.opacity)
                            }

                            Spacer()

                            TranslateButton(englishText: text, accentColor: accentColor, showInline: false)
                        }

                        TranslationOverlay(englishText: text, accentColor: accentColor)

                        // Confirm button
                        if audioFinished {
                            Button {
                                advanceToNext()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: currentIndex < steps.count - 1 ? "checkmark" : "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(currentIndex < steps.count - 1 ? "Got it, next" : "All Done")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(24)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex)
                    .onAppear {
                        audioFinished = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let step = steps[currentIndex]
                            let text = stepText(for: step)
                            let pid = stepPlaybackID(for: step)
                            if !player.isPlaying(id: pid) {
                                player.togglePlayback(id: pid, text: text, sourceLabel: "Guided Sequence")
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !audioFinished { withAnimation { audioFinished = true } }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentColor)

                        Text("Speaking Order 已掌握！")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Continue to the next section")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete(EnglishSpeechPlayer.playbackID(for: allStepsText, category: "sequence-all"))
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: currentIndex)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: audioFinished)
        .animation(.spring(duration: 0.4), value: allDone)
        .onChange(of: player.activePlaybackID) { oldValue, newValue in
            let currentPid = stepPlaybackID(for: steps[currentIndex])
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                withAnimation {
                    audioFinished = true
                }
            }
        }
        .background(ClearBackgroundView())
    }

    private func advanceToNext() {
        if currentIndex < steps.count - 1 {
            withAnimation {
                currentIndex += 1
                audioFinished = false
            }
        } else {
            withAnimation {
                allDone = true
            }
        }
    }
}

// MARK: - Vocabulary Step
private enum VocabCategory: String, CaseIterable {
    case core
    case extended
    case phrases

    var title: String {
        switch self {
        case .core: "Core"
        case .extended: "Extended"
        case .phrases: "Phrases"
        }
    }

    var icon: String {
        switch self {
        case .core: "textbook.fill"
        case .extended: "sparkles"
        case .phrases: "text.quote"
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
        case .list: "List"
        case .flashcard: "Cards"
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
    @State private var flashcardIndex = 0
    @State private var flashcardFlipped = false
    @State private var appeared = false
    @State private var revealedWords: Set<String> = []
    @State private var viewedWords: Set<String> = []
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

    private var phraseItems: [VocabItem] {
        task.phrases.map { phrase in
            VocabItem(
                word: phrase.phrase,
                phonetic: "",
                meaning: phrase.meaning ?? "",
                englishMeaning: "",
                example: phrase.example,
                exampleTranslation: "",
                band: .core,
                providedPartOfSpeech: "phrase",
                sourceBand: phrase.sourceBand,
                nativeNote: phrase.nativeNote
            )
        }
    }

    private var currentFlashcardItems: [VocabItem] {
        switch selectedCategory {
        case .core: coreItems
        case .extended: upgradeItems + advancedItems
        case .phrases: phraseItems
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "词汇与词组",
                    subtitle: "先抓核心词汇，再学实用词组和升级表达。",
                    englishTitle: "Key Vocabulary",
                    englishSubtitle: "Master core words first, then learn phrases and upgrades.",
                    accentColor: Color(hex: "4A90D9")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "character.book.closed.fill",
                    title: "词汇与词组",
                    english: "Vocabulary & Phrases",
                    subtitle: "Master \(coreItems.count) core words · \(task.phrases.count) phrases",
                    accentColor: Color(hex: "4A90D9"),
                    secondaryColor: Color(hex: "7AB4E8")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Category switcher
            categorySwitcher
                .staggerIn(index: 1, appeared: appeared)

            flashcardView
                .staggerIn(index: 2, appeared: appeared)
        }
        .sheet(item: $selectedItem) { item in
            VocabDetailSheet(item: item, accentColor: accentColor)
                .presentationBackground(AppColors.background)
        }
        .onAppear {
            appeared = true
            markCurrentCardViewed()
            updateVocabProgress()
        }
        .onChange(of: revealedWords.count) { _, _ in
            updateVocabProgress()
        }
        .onChange(of: viewedWords.count) { _, _ in
            updateVocabProgress()
        }
        .onChange(of: flashcardIndex) { _, _ in
            markCurrentCardViewed()
        }
        .onChange(of: selectedCategory) { _, _ in
            markCurrentCardViewed()
        }
        .onChange(of: listenedWords.count) { _, _ in
            updateVocabProgress()
        }
    }

    private var allCoreWords: Set<String> {
        Set(coreItems.map { $0.word })
    }

    private func markCurrentCardViewed() {
        let items = currentFlashcardItems
        guard !items.isEmpty else { return }
        let item = items[flashcardIndex % items.count]
        viewedWords.insert(item.word)
    }

    private func updateVocabProgress() {
        let allWords = Set(task.vocabulary.map { $0.word } + task.phrases.map { $0.phrase })
        let viewed = allWords.intersection(viewedWords).count
        let total = allWords.count
        if viewed >= total {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "\(total - viewed) cards remaining"
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
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
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
                    .overlay(alignment: .topLeading) {
                        Text(selectedCategory.title)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor.opacity(0.45))
                            .padding(12)
                    }
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
                            let nextIndex = flashcardIndex + 1
                            if nextIndex >= items.count {
                                // Auto-advance to next category
                                let allCats = VocabCategory.allCases
                                if let currentIdx = allCats.firstIndex(of: selectedCategory),
                                   currentIdx + 1 < allCats.count {
                                    selectedCategory = allCats[currentIdx + 1]
                                    flashcardIndex = 0
                                } else {
                                    flashcardIndex = 0 // wrap around on last category
                                }
                            } else {
                                flashcardIndex = nextIndex
                            }
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
                    HStack(spacing: 5) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(category.title)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                            .fixedSize()
                        Text("\(count)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(isSelected ? 0.22 : 0.08))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(isSelected ? .white : AppColors.secondText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
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
                sectionTag(title: "Intermediate", count: upgradeItems.count, color: Color(hex: "F59E0B"), caption: "Everyday expression upgrades")
            }

            Divider().background(AppColors.border.opacity(0.35))

            DisclosureGroup(isExpanded: $showAdvanced) {
                VStack(spacing: 10) {
                    vocabList(items: advancedItems)
                }
                .padding(.top, 10)
            } label: {
                sectionTag(title: "Advanced", count: advancedItems.count, color: Color(hex: "EF4444"), caption: "Advanced expression & depth")
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
                        Text("Definition")
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
                        Text("Pronunciation")
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
                            Text("Example")
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
            .navigationTitle("Word Details")
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
    @State private var showPhrasesGuide = false
    private var hasLessonContent: Bool { task.lessonContent != nil }
    private let phraseColor = Color(hex: "10B981")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "实用词组",
                    subtitle: "用短语拉开自然度，避免一句一句直译。",
                    englishTitle: "Useful Phrases",
                    englishSubtitle: "Use phrases for naturalness, avoid word-by-word translation.",
                    accentColor: phraseColor
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "quote.bubble.fill",
                    title: "实用词组",
                    english: "Useful Phrases",
                    subtitle: "Master \(task.phrases.count) native phrases for natural speech",
                    accentColor: phraseColor,
                    secondaryColor: Color(hex: "34D399")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Section header with Guide
            HStack {
                Text("\(task.phrases.count) Phrases")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(phraseColor)

                Text("\(listenedPhrases.count)/\(task.phrases.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(phraseColor.opacity(0.6))

                Spacer()

                Button {
                    showPhrasesGuide = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Guide")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(phraseColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
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
        .fullScreenCover(isPresented: $showPhrasesGuide) {
            PhrasesGuidedView(
                phrases: task.phrases,
                accentColor: phraseColor,
                onComplete: { listened in
                    listenedPhrases.formUnion(listened)
                }
            )
        }
    }

    private func updatePhrasesProgress() {
        // Low bar: viewing the page is enough to proceed
        canComplete = appeared
        progressHint = appeared ? nil : "Browse phrase content"
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

// MARK: - Phrases Guided View (Immersive)

private struct PhrasesGuidedView: View {
    let phrases: [PhraseItem]
    let accentColor: Color
    var onComplete: (Set<String>) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var audioFinished = false
    @State private var listenedPhrases: Set<String> = []
    @State private var allDone = false
    @State private var showExample = false

    private func phrasePlaybackID(_ phrase: PhraseItem) -> String {
        EnglishSpeechPlayer.playbackID(for: phrase.phrase, category: "phrase-guide")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        player.stopPlayback()
                        onComplete(listenedPhrases)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("\(currentIndex + 1) / \(phrases.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(phrases.count), height: 4)
                            .animation(.spring(duration: 0.5), value: currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if !allDone {
                    let phrase = phrases[currentIndex]
                    let pid = phrasePlaybackID(phrase)

                    VStack(alignment: .leading, spacing: 16) {
                        // Number + phrase
                        HStack(spacing: 10) {
                            Text("\(currentIndex + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(phrase.phrase)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()
                        }

                        // Meaning
                        if let meaning = phrase.meaning {
                            Text(meaning)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                        }

                        // Example (always shown in guide mode)
                        if !phrase.example.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "text.quote")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Example")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(accentColor)

                                Text(phrase.example)
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppColors.secondText)
                                    .italic()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(4)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(accentColor.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Native note
                        if let note = phrase.nativeNote {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                                .lineSpacing(2)
                        }

                        // Audio + translate
                        HStack(spacing: 12) {
                            CompactPlayButton(
                                text: phrase.phrase,
                                playbackID: pid,
                                sourceLabel: "Guided Phrase",
                                accentColor: accentColor
                            )

                            if player.isPlaying(id: pid) || player.isPaused(id: pid) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor.opacity(0.15))
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(accentColor)
                                            .frame(width: geo.size.width * player.progress, height: 4)
                                    }
                                }
                                .frame(height: 4)
                                .transition(.opacity)
                            }

                            Spacer()

                            TranslateButton(englishText: phrase.phrase + ". " + phrase.example, accentColor: accentColor, showInline: false)
                        }

                        TranslationOverlay(englishText: phrase.phrase + ". " + phrase.example, accentColor: accentColor)

                        // Confirm
                        if audioFinished {
                            Button {
                                advanceToNext()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: currentIndex < phrases.count - 1 ? "checkmark" : "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(currentIndex < phrases.count - 1 ? "Got it" : "All Done")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(24)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex)
                    .onAppear {
                        audioFinished = false
                        showExample = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let phrase = phrases[currentIndex]
                            let pid = phrasePlaybackID(phrase)
                            if !player.isPlaying(id: pid) {
                                player.togglePlayback(id: pid, text: phrase.phrase, sourceLabel: "Guided Phrase")
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !audioFinished { withAnimation { audioFinished = true } }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentColor)
                        Text("All Phrases Learned!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Continue to the next step")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete(listenedPhrases)
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: currentIndex)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: audioFinished)
        .animation(.spring(duration: 0.4), value: allDone)
        .onChange(of: player.activePlaybackID) { oldValue, newValue in
            let currentPid = phrasePlaybackID(phrases[currentIndex])
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                withAnimation { audioFinished = true }
                listenedPhrases.insert(phrases[currentIndex].phrase)
            }
        }
        .background(ClearBackgroundView())
    }

    private func advanceToNext() {
        listenedPhrases.insert(phrases[currentIndex].phrase)
        if currentIndex < phrases.count - 1 {
            withAnimation {
                currentIndex += 1
                audioFinished = false
            }
        } else {
            withAnimation { allDone = true }
        }
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
    @State private var listenedAudioIds: Set<String> = []
    @State private var showFrameworkGuide = false
    private let labels = ["Opening", "Source", "Usage", "Example", "Closing"]
    private var lesson: LessonContent? { task.lessonContent }

    private var totalSentences: Int { task.frameworkSentences.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "表达框架",
                    subtitle: "先看总结构，再补连接表达和升级表达。",
                    englishTitle: "Expression Framework",
                    englishSubtitle: "See the structure first, then add connectors and upgrades.",
                    accentColor: Color(hex: "8B5CF6")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "rectangle.3.group.fill",
                    title: "表达框架",
                    english: "Expression Framework",
                    subtitle: "Master templates for structured expression",
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
        .onChange(of: listenedAudioIds.count) { _, _ in
            updateFrameworkProgress()
        }
        .fullScreenCover(isPresented: $showFrameworkGuide) {
            if let lesson {
                FrameworkGuidedView(
                    framework: lesson.framework,
                    accentColor: frameworkColor,
                    onComplete: { ids in
                        listenedAudioIds.formUnion(ids)
                    }
                )
            }
        }
    }

    private func updateFrameworkProgress() {
        // Lesson content: complete on appear (content is self-paced)
        if lesson != nil {
            canComplete = true
            progressHint = nil
            return
        }
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
            progressHint = "\(remaining) framework sentences remaining"
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
                            label: index < labels.count ? labels[index] : "Point",
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
                        title: "Upgraded Expressions",
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
        let totalItems = 1 + lesson.framework.defaultStructure.count + lesson.framework.deliveryMarkers.count
        return VStack(alignment: .leading, spacing: 16) {
            // Section header with Guide
            HStack {
                Text("\(totalItems) Framework Items")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(frameworkColor)
                Spacer()
                Button {
                    showFrameworkGuide = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Guide")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(frameworkColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .staggerIn(index: 1, appeared: appeared)

            // Framework Goal
            let goalText = lesson.framework.goal
            let goalPlaybackId = EnglishSpeechPlayer.playbackID(for: goalText, category: "fw-goal")

            HStack(spacing: 8) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(frameworkColor)
                Text("Framework Goal")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(frameworkColor)
                Spacer()
                HStack(spacing: 6) {
                    CompactPlayButton(
                        text: goalText,
                        playbackID: goalPlaybackId,
                        sourceLabel: "Framework Goal",
                        accentColor: frameworkColor
                    )
                    TranslateButton(englishText: goalText, accentColor: frameworkColor, showInline: false)
                }
            }
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                Text(goalText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                TranslationOverlay(englishText: goalText, accentColor: frameworkColor)
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(frameworkColor.opacity(0.3))
            )
            .staggerIn(index: 3, appeared: appeared)

            // Speaking Structure — unified card with Opening/Body/Closing
            let allStructureTexts = lesson.framework.defaultStructure.flatMap { [$0.section] + $0.moves }
            let allStructureText = lesson.framework.defaultStructure.map { "\($0.section). \($0.moves.joined(separator: ". "))" }.joined(separator: " ")
            let structurePlaybackId = EnglishSpeechPlayer.playbackID(for: allStructureText, category: "fw-structure-all")

            HStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(frameworkColor)
                Text("Speaking Structure")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(frameworkColor)
                Spacer()
                HStack(spacing: 6) {
                    CompactPlayButton(
                        text: allStructureText,
                        playbackID: structurePlaybackId,
                        sourceLabel: "Speaking Structure",
                        accentColor: frameworkColor
                    )
                    BatchTranslateButton(texts: allStructureTexts, accentColor: frameworkColor)
                }
            }
            .staggerIn(index: 4, appeared: appeared)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(lesson.framework.defaultStructure, id: \.section) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.section)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(frameworkColor.opacity(0.7))
                            .clipShape(Capsule())

                        ForEach(section.moves, id: \.self) { move in
                            VStack(alignment: .leading, spacing: 3) {
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
                                TranslationOverlay(englishText: move, accentColor: frameworkColor)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(frameworkColor.opacity(0.3))
            )
            .staggerIn(index: 5, appeared: appeared)

            // Delivery Markers
            let markerColor = Color(hex: "5B6EF5")
            let markerTexts = lesson.framework.deliveryMarkers
            let allMarkersText = markerTexts.joined(separator: ". ")
            let markersPlaybackId = EnglishSpeechPlayer.playbackID(for: allMarkersText, category: "fw-markers-all")

            HStack(spacing: 8) {
                Image(systemName: "text.quote")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(markerColor)
                Text("Delivery Markers")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(markerColor)
                Spacer()
                HStack(spacing: 6) {
                    CompactPlayButton(
                        text: allMarkersText,
                        playbackID: markersPlaybackId,
                        sourceLabel: "Delivery Markers",
                        accentColor: markerColor
                    )
                    BatchTranslateButton(texts: markerTexts, accentColor: markerColor)
                }
            }
            .staggerIn(index: 6, appeared: appeared)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(markerTexts, id: \.self) { marker in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(markerColor)
                                .padding(.top, 3)
                            Text(marker)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        TranslationOverlay(englishText: marker, accentColor: markerColor)
                    }
                }
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(markerColor.opacity(0.3))
            )
            .staggerIn(index: 7, appeared: appeared)
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

// MARK: - Framework Guided View (Immersive)

private enum FrameworkGuideItem: Identifiable {
    case goal(text: String)
    case section(name: String, moves: [String])
    case marker(index: Int, text: String)

    var id: String {
        switch self {
        case .goal: "goal"
        case .section(let name, _): "section-\(name)"
        case .marker(let i, _): "marker-\(i)"
        }
    }

    var playableText: String {
        switch self {
        case .goal(let text): text
        case .section(_, let moves): moves.joined(separator: ". ")
        case .marker(_, let text): text
        }
    }

    var playbackID: String {
        switch self {
        case .goal: EnglishSpeechPlayer.playbackID(for: playableText, category: "fw-goal")
        case .section(let name, _): EnglishSpeechPlayer.playbackID(for: name + playableText, category: "fw-section")
        case .marker: EnglishSpeechPlayer.playbackID(for: playableText, category: "fw-marker")
        }
    }

    var sectionLabel: String {
        switch self {
        case .goal: "Framework Goal"
        case .section: "Structure"
        case .marker: "Delivery Marker"
        }
    }

    var sectionIcon: String {
        switch self {
        case .goal: "rectangle.3.group.fill"
        case .section: "list.bullet.indent"
        case .marker: "text.quote"
        }
    }

    var color: Color {
        switch self {
        case .goal, .section: Color(hex: "8B5CF6")
        case .marker: Color(hex: "5B6EF5")
        }
    }
}

private struct FrameworkGuidedView: View {
    let framework: LessonContent.Framework
    let accentColor: Color
    var onComplete: (Set<String>) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var audioFinished = false
    @State private var completedIds: Set<String> = []
    @State private var allDone = false

    private var items: [FrameworkGuideItem] {
        var result: [FrameworkGuideItem] = [.goal(text: framework.goal)]
        for section in framework.defaultStructure {
            result.append(.section(name: section.section, moves: section.moves))
        }
        for (i, marker) in framework.deliveryMarkers.enumerated() {
            result.append(.marker(index: i, text: marker))
        }
        return result
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                HStack {
                    Button {
                        player.stopPlayback()
                        onComplete(completedIds)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if !allDone {
                        let item = items[currentIndex]
                        HStack(spacing: 5) {
                            Image(systemName: item.sectionIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(item.sectionLabel)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(item.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(item.color.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(currentIndex + 1) / \(items.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(allDone ? accentColor : items[currentIndex].color)
                            .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(items.count), height: 4)
                            .animation(.spring(duration: 0.5), value: currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if !allDone {
                    cardForItem(items[currentIndex])
                        .padding(.horizontal, 20)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(currentIndex)
                        .onAppear {
                            audioFinished = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let item = items[currentIndex]
                                let pid = item.playbackID
                                if !player.isPlaying(id: pid) {
                                    player.togglePlayback(id: pid, text: item.playableText, sourceLabel: item.sectionLabel)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                if !audioFinished { withAnimation { audioFinished = true } }
                            }
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentColor)
                        Text("Framework Mastered!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Continue to the next step")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete(completedIds)
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: currentIndex)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: audioFinished)
        .animation(.spring(duration: 0.4), value: allDone)
        .onChange(of: player.activePlaybackID) { oldValue, newValue in
            let currentPid = items[currentIndex].playbackID
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                withAnimation { audioFinished = true }
                completedIds.insert(currentPid)
            }
        }
        .background(ClearBackgroundView())
    }

    @ViewBuilder
    private func cardForItem(_ item: FrameworkGuideItem) -> some View {
        let color = item.color
        let pid = item.playbackID

        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: item.sectionIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(Circle())
                Text(item.sectionLabel)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
            }

            switch item {
            case .goal(let text):
                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

            case .section(let name, let moves):
                // Section name tag
                Text(name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.7))
                    .clipShape(Capsule())

                // Moves
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(moves, id: \.self) { move in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(color)
                                .padding(.top, 2)
                            Text(move)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }
                }

            case .marker(_, let text):
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                        .padding(.top, 2)
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }

            // Audio + translate
            HStack(spacing: 12) {
                CompactPlayButton(
                    text: item.playableText,
                    playbackID: pid,
                    sourceLabel: item.sectionLabel,
                    accentColor: color
                )

                if player.isPlaying(id: pid) || player.isPaused(id: pid) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(0.15))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: geo.size.width * player.progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .transition(.opacity)
                }

                Spacer()

                TranslateButton(englishText: item.playableText, accentColor: color, showInline: false)
            }

            TranslationOverlay(englishText: item.playableText, accentColor: color)

            if audioFinished {
                Button {
                    advanceToNext()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: currentIndex < items.count - 1 ? "checkmark" : "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(currentIndex < items.count - 1 ? "Got it" : "All Done")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
    }

    private func advanceToNext() {
        completedIds.insert(items[currentIndex].playbackID)
        if currentIndex < items.count - 1 {
            withAnimation {
                currentIndex += 1
                audioFinished = false
            }
        } else {
            withAnimation { allDone = true }
        }
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
    @State private var showSampleGuide = false
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
                    englishTitle: "Sample Answers",
                    englishSubtitle: "Compare Band 6/7/8 for depth and expression differences.",
                    accentColor: Color(hex: "EC4899")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "doc.richtext.fill",
                    title: "范文学习",
                    english: "Sample Answers",
                    subtitle: "Three-level model answers for comparison",
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

            if selectedBand < task.sampleAnswers.count {
                let sample = task.sampleAnswers[selectedBand]
                let bandColor = bandColors[selectedBand]
                let samplePlaybackId = EnglishSpeechPlayer.playbackID(for: sample.content, category: "sample-\(selectedBand)")

                // Band framework guide (if available)
                if let bandGuide = sample.bandGuide {
                    let guideTexts = bandGuide.opening + bandGuide.body + bandGuide.closing

                    HStack(spacing: 8) {
                        Text("Band \(bandGuide.band) Structure")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(bandColor)
                        Spacer()
                        CompactPlayButton(
                            text: guideTexts.joined(separator: ". "),
                            playbackID: EnglishSpeechPlayer.playbackID(for: guideTexts.joined(separator: ". "), category: "band-guide"),
                            sourceLabel: "Band Guide",
                            accentColor: bandColor
                        )
                    }
                    .staggerIn(index: 2, appeared: appeared)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(bandGuide.focus)
                                .font(.caption.bold())
                                .foregroundStyle(bandColor)
                            Spacer()
                        }

                        ForEach(["Opening", "Body", "Closing"], id: \.self) { section in
                            let lines = section == "Opening" ? bandGuide.opening : section == "Body" ? bandGuide.body : bandGuide.closing
                            VStack(alignment: .leading, spacing: 6) {
                                Text(section)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(bandColor.opacity(0.7))
                                    .clipShape(Capsule())

                                ForEach(lines, id: \.self) { line in
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                            .foregroundStyle(bandColor.opacity(0.3))
                    )
                    .staggerIn(index: 3, appeared: appeared)
                }

                // Sample Answer
                HStack(spacing: 8) {
                    Text("\(sample.band) · \(sample.wordCount) words")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(bandColor)
                    Spacer()
                    HStack(spacing: 6) {
                        Button {
                            showSampleGuide = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8, weight: .bold))
                                Text("Guide")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .fixedSize()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(bandColor)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        CompactPlayButton(
                            text: sample.content,
                            playbackID: samplePlaybackId,
                            sourceLabel: "Sample Answer",
                            accentColor: bandColor,
                            onPlay: { listenedBands.insert(selectedBand) }
                        )

                        let sampleSentences = sample.content.components(separatedBy: ". ").map { $0.hasSuffix(".") ? $0 : $0 + "." }.filter { $0.count > 2 }
                        BatchTranslateButton(texts: sampleSentences, accentColor: bandColor)
                    }
                }
                .staggerIn(index: 4, appeared: appeared)

                VStack(alignment: .leading, spacing: 10) {
                    let sentences = sample.content.components(separatedBy: ". ").map { $0.hasSuffix(".") ? $0 : $0 + "." }.filter { $0.count > 2 }
                    ForEach(sentences, id: \.self) { sentence in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sentence)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                            TranslationOverlay(englishText: sentence, accentColor: bandColor)
                        }
                    }
                }
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                        .foregroundStyle(bandColor.opacity(0.3))
                )
                .staggerIn(index: 5, appeared: appeared)

                // Expression Upgrades
                if !sample.upgrades.isEmpty {
                    let upgradeTexts = sample.upgrades.flatMap { [$0.original, $0.improved, $0.why] }
                    let upgradePlayText = sample.upgrades.map { "Original: \($0.original). Improved: \($0.improved)" }.joined(separator: ". ")

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(bandColor)
                        Text("Expression Upgrades")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(bandColor)
                        Spacer()
                        HStack(spacing: 6) {
                            CompactPlayButton(
                                text: upgradePlayText,
                                playbackID: EnglishSpeechPlayer.playbackID(for: upgradePlayText, category: "upgrades-\(selectedBand)"),
                                sourceLabel: "Expression Upgrades",
                                accentColor: bandColor
                            )
                            BatchTranslateButton(texts: upgradeTexts, accentColor: bandColor)
                        }
                    }
                    .staggerIn(index: 6, appeared: appeared)

                    VStack(alignment: .leading, spacing: 12) {
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
                                TranslationOverlay(englishText: item.original, accentColor: Color(hex: "EF4444"))

                                HStack(alignment: .top, spacing: 8) {
                                    Text("Improved")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(bandColor)
                                    Text(item.improved)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                TranslationOverlay(englishText: item.improved, accentColor: bandColor)

                                Text(item.why)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondText)
                                    .fixedSize(horizontal: false, vertical: true)
                                TranslationOverlay(englishText: item.why, accentColor: bandColor)

                                if !item.note.isEmpty {
                                    Text(item.note)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if item.original != sample.upgrades.last?.original {
                                    Divider().background(AppColors.border.opacity(0.5))
                                }
                            }
                        }
                    }
                    .padding(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                            .foregroundStyle(bandColor.opacity(0.3))
                    )
                    .staggerIn(index: 7, appeared: appeared)
                }
            }
        }
        .onAppear {
            appeared = true
            canComplete = true
            progressHint = nil
        }
        .fullScreenCover(isPresented: $showSampleGuide) {
            if selectedBand < task.sampleAnswers.count {
                SampleGuidedView(
                    sample: task.sampleAnswers[selectedBand],
                    bandColor: bandColors[selectedBand],
                    onComplete: {
                        listenedBands.insert(selectedBand)
                    }
                )
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

// MARK: - Sample Guided View (Immersive)

private enum SampleGuideItem: Identifiable {
    case sampleText(band: String, content: String, wordCount: Int)
    case upgrade(index: Int, upgrade: SampleAnswer.Upgrade)

    var id: String {
        switch self {
        case .sampleText(let band, _, _): "sample-\(band)"
        case .upgrade(let i, _): "upgrade-\(i)"
        }
    }

    var playableText: String {
        switch self {
        case .sampleText(_, let content, _): content
        case .upgrade(_, let u): u.improved
        }
    }

    var sectionLabel: String {
        switch self {
        case .sampleText: "Sample Answer"
        case .upgrade: "Expression Upgrade"
        }
    }

    var sectionIcon: String {
        switch self {
        case .sampleText: "doc.richtext.fill"
        case .upgrade: "arrow.up.circle.fill"
        }
    }
}

private struct SampleGuidedView: View {
    let sample: SampleAnswer
    let bandColor: Color
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var audioFinished = false
    @State private var allDone = false

    private var items: [SampleGuideItem] {
        var result: [SampleGuideItem] = [
            .sampleText(band: sample.band, content: sample.content, wordCount: sample.wordCount)
        ]
        for (i, upgrade) in sample.upgrades.enumerated() {
            result.append(.upgrade(index: i, upgrade: upgrade))
        }
        return result
    }

    private func playbackID(for item: SampleGuideItem) -> String {
        switch item {
        case .sampleText: EnglishSpeechPlayer.playbackID(for: item.playableText, category: "sample-guide")
        case .upgrade: EnglishSpeechPlayer.playbackID(for: item.playableText, category: "sample-upgrade-guide")
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                HStack {
                    Button {
                        player.stopPlayback()
                        onComplete()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if !allDone {
                        let item = items[currentIndex]
                        HStack(spacing: 5) {
                            Image(systemName: item.sectionIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(item.sectionLabel)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(bandColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(bandColor.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(currentIndex + 1) / \(items.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.15))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(bandColor)
                            .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(items.count), height: 4)
                            .animation(.spring(duration: 0.5), value: currentIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer(minLength: 12)

                if !allDone {
                    let item = items[currentIndex]
                    let pid = playbackID(for: item)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header
                            HStack(spacing: 10) {
                                Image(systemName: item.sectionIcon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(bandColor)
                                    .clipShape(Circle())
                                Text(item.sectionLabel)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryText)
                                Spacer()
                            }

                            switch item {
                            case .sampleText(let band, let content, let wc):
                                HStack {
                                    Text(band)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(bandColor)
                                        .clipShape(Capsule())
                                    Text("\(wc) words")
                                        .font(.caption.bold())
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                let sentences = content.components(separatedBy: ". ").map { $0.hasSuffix(".") ? $0 : $0 + "." }.filter { $0.count > 2 }
                                ForEach(sentences, id: \.self) { sentence in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sentence)
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppColors.secondText)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineSpacing(3)
                                        TranslationOverlay(englishText: sentence, accentColor: bandColor)
                                    }
                                }

                            case .upgrade(_, let upgrade):
                                // Original vs Improved
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("ORIGINAL")
                                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: "EF4444"))
                                            .clipShape(Capsule())
                                        Text(upgrade.original)
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppColors.tertiaryText)
                                            .strikethrough(color: Color(hex: "EF4444").opacity(0.4))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    HStack(alignment: .top, spacing: 10) {
                                        Text("IMPROVED")
                                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(AppColors.success)
                                            .clipShape(Capsule())
                                        Text(upgrade.improved)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(AppColors.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(bandColor.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                Text(upgrade.why)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(2)

                                if !upgrade.note.isEmpty {
                                    Text(upgrade.note)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Audio + translate
                            HStack(spacing: 12) {
                                CompactPlayButton(
                                    text: item.playableText,
                                    playbackID: pid,
                                    sourceLabel: item.sectionLabel,
                                    accentColor: bandColor
                                )

                                if player.isPlaying(id: pid) || player.isPaused(id: pid) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(bandColor.opacity(0.15))
                                                .frame(height: 4)
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(bandColor)
                                                .frame(width: geo.size.width * player.progress, height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                    .transition(.opacity)
                                }

                                Spacer()

                                TranslateButton(englishText: item.playableText, accentColor: bandColor, showInline: false)
                            }

                            TranslationOverlay(englishText: item.playableText, accentColor: bandColor)

                            if audioFinished {
                                Button {
                                    advanceToNext()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: currentIndex < items.count - 1 ? "checkmark" : "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text(currentIndex < items.count - 1 ? "Got it" : "All Done")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(bandColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(24)
                    }
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex)
                    .onAppear {
                        audioFinished = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let item = items[currentIndex]
                            let pid = playbackID(for: item)
                            if !player.isPlaying(id: pid) {
                                player.togglePlayback(id: pid, text: item.playableText, sourceLabel: item.sectionLabel)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if !audioFinished { withAnimation { audioFinished = true } }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(bandColor)
                        Text("\(sample.band) Sample Complete!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Try other bands or continue to the next step")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete()
                            dismiss()
                        }
                    }
                }

                Spacer(minLength: 12)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: currentIndex)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: audioFinished)
        .animation(.spring(duration: 0.4), value: allDone)
        .onChange(of: player.activePlaybackID) { oldValue, newValue in
            let currentPid = playbackID(for: items[currentIndex])
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                withAnimation { audioFinished = true }
            }
        }
        .background(ClearBackgroundView())
    }

    private func advanceToNext() {
        if currentIndex < items.count - 1 {
            withAnimation {
                currentIndex += 1
                audioFinished = false
            }
        } else {
            withAnimation { allDone = true }
        }
    }
}

// MARK: - Practice Prompt
private enum PracticeInputMode: String, CaseIterable, Identifiable {
    case text = "Text"
    case voice = "Voice"

    var id: String { rawValue }
}

private enum PracticeLanguageMode: String, CaseIterable, Identifiable {
    case native = "Native"
    case english = "English"

    var id: String { rawValue }
}

struct PracticePromptView: View {
    let stageId: Int
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?
    private let labels = ["Opening", "Source", "Usage", "Example", "Closing"]
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
                    englishTitle: "Speaking Practice",
                    englishSubtitle: "Speak the content out loud — don't just read.",
                    accentColor: Color(hex: "EF4444")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "mic.fill",
                    title: "口语练习",
                    english: "Speaking Practice",
                    subtitle: "Real practice — speak English out loud",
                    accentColor: Color(hex: "EF4444"),
                    secondaryColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            topicCard
                .staggerIn(index: 1, appeared: appeared)

            if let lesson {
                // Speaking guide — checklist + prompts in one clean card
                let checklistTexts = lesson.practice.checklist
                let promptTexts = lesson.practice.selfPrompts

                HStack(spacing: 8) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(practiceColor)
                    Text("Speaking Guide")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(practiceColor)
                    Spacer()
                    BatchTranslateButton(texts: checklistTexts + promptTexts, accentColor: practiceColor)
                }
                .staggerIn(index: 2, appeared: appeared)

                VStack(alignment: .leading, spacing: 14) {
                    // Checklist
                    ForEach(checklistTexts, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 4) {
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
                            TranslationOverlay(englishText: item, accentColor: practiceColor)
                        }
                    }

                    if !promptTexts.isEmpty {
                        Divider().background(AppColors.border.opacity(0.5))

                        // Self prompts as simple questions
                        ForEach(promptTexts, id: \.self) { prompt in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(practiceColor.opacity(0.7))
                                        .padding(.top, 2)
                                    Text(prompt)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                TranslationOverlay(englishText: prompt, accentColor: practiceColor)
                            }
                        }
                    }
                }
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                        .foregroundStyle(practiceColor.opacity(0.3))
                )
                .staggerIn(index: 3, appeared: appeared)
            }

            inputCard
                .staggerIn(index: 4, appeared: appeared)
            actionArea
                .staggerIn(index: 5, appeared: appeared)

            if !translatedEnglish.isEmpty {
                resultCard(
                    title: "English Result",
                    text: translatedEnglish,
                    tint: Color(hex: "4A90D9")
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
        if hasTranslation {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "Submit your answer and get translation"
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

    private var inputCard: some View {
        GradientAccentCard(color: Color(hex: "4A90D9"), spacing: 14) {
            StepSectionLabel(icon: "square.and.pencil", title: "Write Your Draft", color: Color(hex: "4A90D9"))

            modeSelector(
                title: "Input Mode",
                items: PracticeInputMode.allCases,
                selected: inputMode
            ) { inputMode = $0 }

            if inputMode == .text {
                modeSelector(
                    title: "Content Type",
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

            Text("Draft auto-saves. You can write in your native language first, then convert to English.")
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
                    Text(speechInput.isRecording ? "Stop" : "Record")
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
                    Text(languageMode == .native ? "Write in your native language, 4-6 sentences..." : "Write your English draft here...")
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
                Text(languageMode == .native ? "Native → English" : "Keep English draft")
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

    private func resultCard(title: String, text: String, tint: Color) -> some View {
        let resultPlaybackId = EnglishSpeechPlayer.playbackID(for: text, category: "practice")
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Spacer()
                CompactPlayButton(
                    text: text,
                    playbackID: resultPlaybackId,
                    sourceLabel: "Practice Result",
                    accentColor: tint,
                    onPlay: { listenedResultAudio = true }
                )
                TranslateButton(englishText: text, accentColor: tint, showInline: false)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(5)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            TranslationOverlay(englishText: text, accentColor: tint)
        }
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                .foregroundStyle(tint.opacity(0.3))
        )
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
