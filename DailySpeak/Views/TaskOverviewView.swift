import SwiftUI

private enum OverviewPresentationPhase {
    case heroEntrance
    case heroTitleReveal
    case heroDescriptionReveal
    case heroDockToTop
    case focusReveal
    case flowReveal
    case stepProgression
    case ready
}

private enum OverviewStepDisplayState {
    case hidden
    case spinning
    case unlocked
    case locked
}

struct TaskOverviewView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var showLearning = false
    @State private var phase: OverviewPresentationPhase = .heroEntrance
    @State private var showCenteredHero = false
    @State private var centeredHeroSettled = false
    @State private var centeredHeroDocking = false
    @State private var darkOverlayOpacity = 0.0
    @State private var heroTitleVisible = false
    @State private var heroPromptChars = 0
    @State private var showDockedHero = false
    @State private var showFocusSection = false
    @State private var showFlowSection = false
    @State private var stepDisplayStates: [OverviewStepDisplayState] = []
    @State private var showStartButton = false

    private var theme: StageTheme { stage.theme }
    private var lessonContent: LessonContent? { task.lessonContent }
    private var heroPromptText: String {
        let chars = Array(task.prompt)
        guard !chars.isEmpty, heroPromptChars > 0 else { return "" }
        return String(chars.prefix(min(heroPromptChars, chars.count)))
    }
    private var centeredHeroOffsetY: CGFloat {
        if centeredHeroDocking { return -220 }
        return centeredHeroSettled ? 0 : -56
    }
    private var centeredHeroScale: CGFloat {
        if centeredHeroDocking { return 0.86 }
        return centeredHeroSettled ? 1 : 0.92
    }
    private var centeredHeroRotation: Double {
        centeredHeroSettled ? 0 : 9
    }
    private var centeredHeroOpacity: Double {
        centeredHeroDocking ? 0.15 : (showCenteredHero ? 1 : 0)
    }
    private var currentUnlockedStepIndex: Int {
        progress.currentStepIndex(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if showDockedHero {
                        dockedHeroCard
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if showFocusSection {
                        focusSectionCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if showFlowSection {
                        flowSectionCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Color.clear.frame(height: showStartButton ? 90 : 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDisabled(phase != .ready)

            if darkOverlayOpacity > 0 {
                Color.black
                    .opacity(darkOverlayOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showCenteredHero {
                centeredHeroCard
                    .padding(.horizontal, 20)
                    .offset(y: centeredHeroOffsetY)
                    .scaleEffect(centeredHeroScale)
                    .rotation3DEffect(.degrees(centeredHeroRotation), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
                    .opacity(centeredHeroOpacity)
                    .zIndex(2)
            }

            if showStartButton {
                startButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .task(id: task.id) {
            await runRevealSequence()
        }
    }

    // MARK: - Hero Card
    private var centeredHeroCard: some View {
        heroBanner(isCentered: true)
            .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 18)
    }

    private var dockedHeroCard: some View {
        heroBanner(isCentered: false)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func heroBanner(isCentered: Bool) -> some View {
        if let lessonContent {
            lessonBanner(lessonContent, isCentered: isCentered)
        } else {
            topBanner(isCentered: isCentered)
        }
    }

    private func topBanner(isCentered: Bool) -> some View {
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
                        lessonChip("Stage \(stage.id)")
                        lessonChip(task.questionType)
                    }

                    Text(task.title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .opacity(isCentered ? (heroTitleVisible ? 1 : 0) : 1)

                    Text(task.englishTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(isCentered ? (heroTitleVisible ? 1 : 0) : 1)
                }

                Spacer(minLength: 10)
                Text(theme.emoji)
                    .font(.system(size: 34))
            }
            .padding(18)
        }
        .frame(height: 125)
        .heroShadow()
    }

    private func lessonBanner(_ lesson: LessonContent, isCentered: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.softGradient)

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 120)
                    .offset(x: geo.size.width - 70, y: -30)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 64)
                    .offset(x: -10, y: 92)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            lessonChip(lesson.topic.stageLabel)
                            lessonChip("Q\(String(format: "%02d", task.id))")
                            lessonChip(task.questionType)
                        }

                        Text(task.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .opacity(isCentered ? (heroTitleVisible ? 1 : 0) : 1)

                        Text(isCentered ? heroPromptText : task.prompt)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Text(theme.emoji)
                        .font(.system(size: 40))
                }

                HStack(spacing: 10) {
                    lessonMetaPill(icon: "clock.fill", text: lesson.practice.targetLength)
                    lessonMetaPill(icon: "text.quote", text: "\(task.sampleAnswers.count) samples")
                    lessonMetaPill(icon: "books.vertical.fill", text: "\(task.vocabulary.count) vocab")
                }
            }
            .padding(20)
        }
        .frame(minHeight: 190)
        .heroShadow()
    }

    private func lessonChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())
    }

    private func lessonMetaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Focus
    private var focusSectionCard: some View {
        Group {
            if let lessonContent {
                lessonSummaryCard(lessonContent)
            } else {
                fallbackFocusCard
            }
        }
    }

    private func lessonSummaryCard(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("学习重点")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text(lesson.practice.targetLength)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.startColor.opacity(0.08))
                    .clipShape(Capsule())
            }

            Text(lesson.topic.learningGoal ?? "先看思路，再学词汇和框架，最后对照范文开口练。")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lesson.strategy.angles, id: \.title) { angle in
                        lessonAngleChip(title: angle.title)
                    }
                }
            }

            HStack(spacing: 8) {
                lessonMiniStat(title: "Angles", value: "\(lesson.strategy.angles.count)")
                lessonMiniStat(title: "Bands", value: "\(task.sampleAnswers.count)")
                lessonMiniStat(title: "Vocab", value: "\(task.vocabulary.count)")
                lessonMiniStat(title: "Samples", value: "\(task.sampleAnswers.count)")
            }

            Divider().background(AppColors.border)

            VStack(alignment: .leading, spacing: 8) {
                Text("建议顺序")
                    .font(.caption.bold())
                    .foregroundStyle(theme.startColor)

                Text("先看答题思路，再学词汇和框架，最后对照范文开口练。")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(16)
        .cardStyle()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func lessonAngleChip(title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(theme.startColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.startColor.opacity(0.08))
            .clipShape(Capsule())
    }

    private func lessonMiniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(AppColors.tertiaryText)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fallbackFocusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("学习重点")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text(task.suggestedTime)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.startColor.opacity(0.08))
                    .clipShape(Capsule())
            }

            Text("打开这道题时，先理解题意，再抓关键词，最后按照步骤开口练。")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)

            VStack(spacing: 12) {
                ForEach(Array(task.tips.prefix(3).enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(theme.startColor.opacity(0.12))
                                .frame(width: 26, height: 26)
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.startColor)
                        }

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Flow
    private var flowSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("学习流程")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text("\(task.steps.count) steps")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.startColor.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 2)

            VStack(spacing: 0) {
                ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                    let state = stepDisplayState(at: index)
                    if state != .hidden {
                        flowStepRow(step: step, index: index, state: state)
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                        if index < task.steps.count - 1 {
                            Rectangle()
                                .fill(connectorColor(for: index))
                                .frame(width: 2)
                                .frame(height: 18)
                                .padding(.leading, 15)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private func flowStepRow(step: LearningStep, index: Int, state: OverviewStepDisplayState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 30, height: 30)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    switch state {
                    case .hidden:
                        EmptyView()
                    case .spinning:
                        StepSpinnerBadge(number: index + 1, color: step.type.color)
                            .frame(width: 30, height: 30)
                    case .unlocked:
                        Circle()
                            .fill(step.type.color.opacity(0.14))
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(step.type.color)
                    case .locked:
                        Circle()
                            .fill(AppColors.surface)
                            .frame(width: 30, height: 30)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.2), value: stepDisplayStates)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: step.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(stepTitleColor(for: step, index: index, state: state))
                    Text(step.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)
                }

                Text(stepSubtitle(for: step, state: state))
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
            .opacity(state == .spinning ? 0.92 : 1)

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func stepDisplayState(at index: Int) -> OverviewStepDisplayState {
        guard stepDisplayStates.indices.contains(index) else { return .hidden }
        return stepDisplayStates[index]
    }

    private func stepTitleColor(for step: LearningStep, index: Int, state: OverviewStepDisplayState) -> Color {
        if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) {
            return AppColors.success
        }

        switch state {
        case .hidden, .spinning:
            return step.type.color
        case .unlocked:
            return step.type.color
        case .locked:
            return AppColors.tertiaryText
        }
    }

    private func stepSubtitle(for step: LearningStep, state: OverviewStepDisplayState) -> String {
        switch state {
        case .locked:
            return "完成前一步后解锁"
        default:
            return step.subtitle
        }
    }

    private func connectorColor(for index: Int) -> Color {
        if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) {
            return AppColors.success.opacity(0.28)
        }

        switch stepDisplayState(at: index) {
        case .unlocked:
            return theme.startColor.opacity(0.22)
        case .locked:
            return AppColors.border.opacity(0.45)
        case .spinning:
            return stepDisplayStates.indices.contains(index) ? task.steps[index].type.color.opacity(0.2) : AppColors.border.opacity(0.3)
        case .hidden:
            return .clear
        }
    }

    // MARK: - Reveal Sequence
    @MainActor
    private func runRevealSequence() async {
        resetRevealState()

        phase = .heroEntrance
        showCenteredHero = true
        withAnimation(.easeOut(duration: 0.18)) {
            darkOverlayOpacity = 0.74
        }
        withAnimation(.spring(duration: 0.72, bounce: 0.16)) {
            centeredHeroSettled = true
        }
        await pause(0.48)
        guard !Task.isCancelled else { return }

        phase = .heroTitleReveal
        withAnimation(.easeOut(duration: 0.3)) {
            heroTitleVisible = true
        }
        await pause(0.24)
        guard !Task.isCancelled else { return }

        phase = .heroDescriptionReveal
        await typeHeroPrompt()
        await pause(0.12)
        guard !Task.isCancelled else { return }

        phase = .heroDockToTop
        withAnimation(.spring(duration: 0.7, bounce: 0.12)) {
            showDockedHero = true
            centeredHeroDocking = true
        }
        await pause(0.55)
        guard !Task.isCancelled else { return }

        showCenteredHero = false
        withAnimation(.easeOut(duration: 0.24)) {
            darkOverlayOpacity = 0
        }

        phase = .focusReveal
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) {
            showFocusSection = true
        }
        await pause(0.26)
        guard !Task.isCancelled else { return }

        phase = .flowReveal
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) {
            showFlowSection = true
        }
        await pause(0.14)
        guard !Task.isCancelled else { return }

        phase = .stepProgression
        await runStepProgression()
        guard !Task.isCancelled else { return }

        phase = .ready
        withAnimation(.spring(duration: 0.45, bounce: 0.12)) {
            showStartButton = true
        }
    }

    @MainActor
    private func runStepProgression() async {
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        for index in task.steps.indices {
            guard !Task.isCancelled else { return }

            withAnimation(.spring(duration: 0.36, bounce: 0.16)) {
                stepDisplayStates[index] = .spinning
            }
            await pause(index == 0 ? 0.42 : 0.32)
            guard !Task.isCancelled else { return }

            withAnimation(.spring(duration: 0.42, bounce: 0.14)) {
                stepDisplayStates[index] = settledStepState(for: index)
            }
            await pause(0.14)
        }
    }

    private func settledStepState(for index: Int) -> OverviewStepDisplayState {
        let currentStep = currentUnlockedStepIndex
        if currentStep >= task.steps.count { return .unlocked }
        return index <= currentStep ? .unlocked : .locked
    }

    @MainActor
    private func typeHeroPrompt() async {
        let characters = Array(task.prompt)
        guard !characters.isEmpty else { return }
        let totalDuration = min(0.82, max(0.48, Double(characters.count) * 0.018))
        let interval = totalDuration / Double(characters.count)

        for index in characters.indices {
            guard !Task.isCancelled else { return }
            heroPromptChars = index + 1
            await pause(interval)
        }
    }

    private func resetRevealState() {
        phase = .heroEntrance
        showCenteredHero = false
        centeredHeroSettled = false
        centeredHeroDocking = false
        darkOverlayOpacity = 0
        heroTitleVisible = false
        heroPromptChars = 0
        showDockedHero = false
        showFocusSection = false
        showFlowSection = false
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        showStartButton = false
    }

    private func pause(_ seconds: Double) async {
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }

    // MARK: - CTA
    private var startButton: some View {
        let currentStep = progress.currentStepIndex(
            stageId: stage.id,
            taskId: task.id,
            totalSteps: task.steps.count
        )
        let taskDone = currentStep >= task.steps.count
        let label = taskDone ? "Review Again" : (currentStep > 0 ? "Continue Learning" : "Start Learning")
        let icon = taskDone ? "arrow.counterclockwise" : "arrow.right"

        return VStack(spacing: 0) {
            LinearGradient(
                colors: [AppColors.background.opacity(0), AppColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            Button {
                showLearning = true
            } label: {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: theme.startColor.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .background(AppColors.background)
            .opacity(showStartButton ? 1 : 0)
            .scaleEffect(showStartButton ? 1 : 0.94)
        }
    }
}

// MARK: - Step Spinner Badge (spinning number)
struct StepSpinnerBadge: View {
    let number: Int
    let color: Color
    @State private var rotation: Double = 0
    @State private var numberVisible = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: 0.35)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.05), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))

            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .scaleEffect(numberVisible ? 1 : 0.3)
                .opacity(numberVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(0.1)) {
                numberVisible = true
            }
        }
    }
}
