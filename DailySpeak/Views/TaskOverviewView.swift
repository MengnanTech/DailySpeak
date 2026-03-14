import SwiftUI

private enum OverviewPresentationPhase: Comparable {
    case idle
    case heroEntrance
    case heroTitleReveal
    case heroDescriptionReveal
    case heroDockToTop
    case focusPopup
    case focusDock
    case flowPopup
    case flowStepSpin
    case flowDock
    case ready
}

private enum OverviewStepDisplayState {
    case hidden
    case spinning
    case checked   // checkmark in popup after spin finishes
    case unlocked
    case locked
}

struct TaskOverviewView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var showLearning = false
    @State private var tappedStepIndex: Int?
    @State private var phase: OverviewPresentationPhase = .idle

    private static let seenTasksKey = "overviewAnimationSeenTasks"
    private var hasSeenAnimation: Bool {
        let seen = UserDefaults.standard.stringArray(forKey: Self.seenTasksKey) ?? []
        return seen.contains("s\(stage.id)_t\(task.id)")
    }
    private func markAnimationSeen() {
        var seen = UserDefaults.standard.stringArray(forKey: Self.seenTasksKey) ?? []
        let key = "s\(stage.id)_t\(task.id)"
        if !seen.contains(key) { seen.append(key) }
        UserDefaults.standard.set(seen, forKey: Self.seenTasksKey)
    }

    // Dark overlay (shared by all popups)
    @State private var darkOverlayOpacity: Double = 0

    // --- Hero card popup ---
    @State private var showCenteredHero = false
    @State private var heroEntranceScale: CGFloat = 0.5
    @State private var heroRotationX: Double = 45
    @State private var heroEntranceOpacity: Double = 0
    @State private var contentRevealProgress: Double = 0
    @State private var heroTitleOpacity: Double = 0
    @State private var heroPromptChars = 0
    @State private var heroMetaOpacity: Double = 0
    @State private var glowIntensity: Double = 0

    // --- Focus card popup ---
    @State private var showCenteredFocus = false
    @State private var focusPopupScale: CGFloat = 0.6
    @State private var focusPopupOpacity: Double = 0
    @State private var focusContentOpacity: Double = 0
    // Focus staggered reveal
    @State private var focusTitleOpacity: Double = 0
    @State private var focusGoalOpacity: Double = 0
    @State private var focusGoalChars: Int = 0
    @State private var focusChipsOpacity: Double = 0
    @State private var focusStatsOpacity: Double = 0
    @State private var focusSuggestionOpacity: Double = 0
    @State private var focusSuggestionChars: Int = 0

    // --- Flow card popup ---
    @State private var showCenteredFlow = false
    @State private var flowPopupScale: CGFloat = 0.6
    @State private var flowPopupOpacity: Double = 0
    @State private var stepDisplayStates: [OverviewStepDisplayState] = []

    // --- Flow step text typewriter ---
    @State private var stepTextChars: [Int] = []

    // --- Popup fly-up offsets for dock transition ---
    @State private var heroPopupOffsetY: CGFloat = 0
    @State private var focusPopupOffsetY: CGFloat = 0
    @State private var flowPopupOffsetY: CGFloat = 0

    // --- Docked content ---
    @State private var showDockedHero = false
    @State private var showDockedFocus = false
    @State private var showDockedFlow = false
    @State private var scrollToFlow = false

    private var theme: StageTheme { stage.theme }
    private var lessonContent: LessonContent? { task.lessonContent }

    private var heroPromptText: String {
        let chars = Array(task.prompt)
        guard !chars.isEmpty, heroPromptChars > 0 else { return "" }
        return String(chars.prefix(min(heroPromptChars, chars.count)))
    }

    private var currentUnlockedStepIndex: Int {
        progress.currentStepIndex(stageId: stage.id, taskId: task.id, totalSteps: task.steps.count)
    }


    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable docked content
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if showDockedHero {
                            heroSectionCard
                                .transition(.asymmetric(
                                    insertion: .offset(y: -20).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                        if showDockedFocus {
                            focusSectionCard
                                .transition(.asymmetric(
                                    insertion: .offset(y: -20).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                        if showDockedFlow {
                            flowSectionCard
                                .id("flowCard")
                                .transition(.asymmetric(
                                    insertion: .offset(y: -20).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }
                        Color.clear.frame(height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .scrollDisabled(phase != .ready)
                .onChange(of: scrollToFlow) {
                    if scrollToFlow {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("flowCard", anchor: .center)
                        }
                        scrollToFlow = false
                    }
                }
            }

            // Cinematic overlay
            if darkOverlayOpacity > 0 {
                ZStack {
                    Color.black.opacity(darkOverlayOpacity * 0.88)
                    RadialGradient(
                        colors: [theme.startColor.opacity(0.12), theme.endColor.opacity(0.04), .clear],
                        center: .center, startRadius: 40, endRadius: 350
                    )
                    .opacity(darkOverlayOpacity)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Hero popup overlay
            if showCenteredHero {
                popupOverlay {
                    heroSectionCard
                        .padding(.horizontal, 10)
                        .shadow(color: theme.startColor.opacity(0.35 * glowIntensity), radius: 28, x: 0, y: 12)
                        .scaleEffect(heroEntranceScale)
                        .rotation3DEffect(.degrees(heroRotationX), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
                        .offset(y: heroPopupOffsetY)
                        .opacity(heroEntranceOpacity)
                }
            }

            // Focus popup overlay
            if showCenteredFocus {
                popupOverlay {
                    focusSectionCard
                        .padding(.horizontal, 24)
                        .opacity(focusContentOpacity)
                        .shadow(color: theme.startColor.opacity(0.2), radius: 20, x: 0, y: 8)
                        .scaleEffect(focusPopupScale)
                        .offset(y: focusPopupOffsetY)
                        .opacity(focusPopupOpacity)
                }
            }

            // Flow popup overlay
            if showCenteredFlow {
                popupOverlay {
                    flowSectionCard
                        .padding(.horizontal, 24)
                        .shadow(color: theme.startColor.opacity(0.2), radius: 20, x: 0, y: 8)
                        .scaleEffect(flowPopupScale)
                        .offset(y: flowPopupOffsetY)
                        .opacity(flowPopupOpacity)
                }
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
            LearningFlowView(stage: stage, task: task, initialStep: tappedStepIndex)
        }
        .task(id: task.id) {
            await runRevealSequence()
        }
        .onDisappear {
            EnglishSpeechPlayer.shared.stopPlayback()
        }
    }

    // Shared popup container
    private func popupOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            Spacer()
            content()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(10)
    }

    // MARK: - Hero Section Card (Unified — same view for popup & docked)

    private var heroSectionCard: some View {
        Group {
            if let lessonContent {
                heroLessonCard(lessonContent)
            } else {
                heroSimpleCard
            }
        }
    }

    private func heroLessonCard(_ lesson: LessonContent) -> some View {
        let isPopup = showCenteredHero
        return VStack(alignment: .leading, spacing: isPopup ? 20 : 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: isPopup ? 12 : 8) {
                    HStack(spacing: 8) {
                        lessonChip(lesson.topic.stageLabel)
                        lessonChip("Q\(String(format: "%02d", task.id))")
                        lessonChip(task.questionType)
                    }
                    .opacity(isPopup ? contentRevealProgress : 1)
                    Text(task.title)
                        .font(.system(size: isPopup ? 34 : 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(isPopup ? heroTitleOpacity : 1)
                    heroPromptView(fullText: task.prompt, isPopup: isPopup)
                }
                Spacer(minLength: 12)
                Text(theme.emoji).font(.system(size: isPopup ? 52 : 40))
                    .opacity(isPopup ? heroTitleOpacity : 1)
            }
            HStack(spacing: 10) {
                lessonMetaPill(icon: "clock.fill", text: lesson.practice.targetLength)
                lessonMetaPill(icon: "text.quote", text: "\(task.sampleAnswers.count) samples")
                lessonMetaPill(icon: "books.vertical.fill", text: "\(task.vocabulary.count) vocab")
            }
            .opacity(isPopup ? heroMetaOpacity : 1)
        }
        .padding(isPopup ? 28 : 20)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(theme.softGradient)
                GeometryReader { geo in
                    Circle().fill(.white.opacity(0.12)).frame(width: 120).offset(x: geo.size.width - 70, y: -30)
                    Circle().fill(.white.opacity(0.08)).frame(width: 64).offset(x: -10, y: 92)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .heroShadow()
    }

    private var heroSimpleCard: some View {
        let isPopup = showCenteredHero
        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    lessonChip("Stage \(stage.id)")
                    lessonChip(task.questionType)
                }
                .opacity(isPopup ? contentRevealProgress : 1)
                Text(task.title).font(.title3.bold()).foregroundStyle(.white)
                    .opacity(isPopup ? heroTitleOpacity : 1)
                Text(task.englishTitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                    .opacity(isPopup ? heroTitleOpacity : 1)
            }
            Spacer(minLength: 10)
            Text(theme.emoji).font(.system(size: 34))
                .opacity(isPopup ? heroTitleOpacity : 1)
        }
        .padding(18)
        .frame(minHeight: 125)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(theme.softGradient)
                GeometryReader { geo in
                    Circle().fill(.white.opacity(0.1)).frame(width: 80).offset(x: geo.size.width - 50, y: -15)
                    Circle().fill(.white.opacity(0.06)).frame(width: 50).offset(x: -15, y: 55)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .heroShadow()
    }

    private func heroPromptView(fullText: String, isPopup: Bool) -> some View {
        let promptFont: Font = isPopup ? .body : .subheadline
        return ZStack(alignment: .topLeading) {
            Text(fullText)
                .font(promptFont).foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isPopup ? 0 : 1)
            Text(heroPromptText)
                .font(promptFont).foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isPopup && heroPromptChars > 0 ? 1 : 0)
        }
    }

    private func lessonChip(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.white.opacity(0.14)).clipShape(Capsule())
    }

    private func lessonMetaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(.white.opacity(0.12)).clipShape(Capsule())
    }

    // MARK: - Focus Section Card

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
        let isPopup = showCenteredFocus
        let goalText = lesson.topic.learningGoal ?? "先看思路，再学词汇和框架，最后对照范文开口练。"
        let goalPlaybackId = EnglishSpeechPlayer.playbackID(for: goalText, category: "focus-goal")
        let accent = theme.startColor

        return VStack(alignment: .leading, spacing: 18) {
            // ── Header ──
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("学习重点")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text(lesson.practice.targetLength)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                Spacer()
            }
            .opacity(isPopup ? focusTitleOpacity : 1)

            // ── Learning goal with accent bar + audio ──
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 10) {
                    focusGoalText(goalText, isPopup: isPopup)

                    // Audio — tap to play
                    HStack(spacing: 5) {
                        Image(systemName: EnglishSpeechPlayer.shared.isPlaying(id: goalPlaybackId) ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(accent)
                            .symbolEffect(.variableColor.iterative, isActive: EnglishSpeechPlayer.shared.isPlaying(id: goalPlaybackId))
                        Text(EnglishSpeechPlayer.shared.isPlaying(id: goalPlaybackId) ? "Playing..." : "Tap to listen")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(accent.opacity(0.8))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(accent.opacity(0.08))
                    .clipShape(Capsule())
                    .onTapGesture {
                        EnglishSpeechPlayer.shared.togglePlayback(
                            id: goalPlaybackId, text: goalText, sourceLabel: "学习重点"
                        )
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isPopup ? focusGoalOpacity : 1)

            // ── Angle chips ──
            FlowLayout(spacing: 8) {
                ForEach(lesson.strategy.angles, id: \.title) { angle in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(accent)
                            .frame(width: 5, height: 5)
                        Text(angle.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(accent.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
            .opacity(isPopup ? focusChipsOpacity : 1)

            // ── Stats row ──
            HStack(spacing: 0) {
                lessonMiniStat(title: "思路", value: "\(lesson.strategy.angles.count)", icon: "sparkles", accent: accent)
                focusStatDivider(accent: accent)
                lessonMiniStat(title: "词汇", value: "\(task.vocabulary.count)", icon: "textformat.abc", accent: accent)
                focusStatDivider(accent: accent)
                lessonMiniStat(title: "范文", value: "\(task.sampleAnswers.count)", icon: "doc.text", accent: accent)
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.04))
            )
            .opacity(isPopup ? focusStatsOpacity : 1)

            // ── Suggestion ──
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.top, 2)
                focusSuggestionText("先看答题思路，再学词汇和框架，最后对照范文开口练。", isPopup: isPopup)
            }
            .opacity(isPopup ? focusSuggestionOpacity : 1)
        }
        .padding(20).cardStyle()
    }

    private func focusStatDivider(accent: Color) -> some View {
        Rectangle()
            .fill(accent.opacity(0.12))
            .frame(width: 0.5, height: 28)
    }

    // Typewriter text views for focus card
    @ViewBuilder
    private func focusGoalText(_ fullText: String, isPopup: Bool) -> some View {
        if isPopup {
            ZStack(alignment: .topLeading) {
                Text(fullText)
                    .font(.subheadline).foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                Text(String(fullText.prefix(focusGoalChars)))
                    .font(.subheadline).foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(focusGoalChars > 0 ? 1 : 0)
            }
        } else {
            Text(fullText)
                .font(.subheadline).foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func focusSuggestionText(_ fullText: String, isPopup: Bool) -> some View {
        if isPopup {
            ZStack(alignment: .topLeading) {
                Text(fullText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                Text(String(fullText.prefix(focusSuggestionChars)))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(focusSuggestionChars > 0 ? 1 : 0)
            }
        } else {
            Text(fullText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func lessonMiniStat(title: String, value: String, icon: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.opacity(0.6))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var fallbackFocusCard: some View {
        let isPopup = showCenteredFocus
        return VStack(alignment: .leading, spacing: 18) {
            // Header with icon badge
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(colors: [theme.startColor, theme.endColor],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 38, height: 38)
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("学习重点")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text(task.suggestedTime)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                Spacer()
            }
            .opacity(isPopup ? focusTitleOpacity : 1)

            // Description with accent bar + typewriter
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [theme.startColor, theme.endColor],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                focusGoalText("打开这道题时，先理解题意，再抓关键词，最后按照步骤开口练。", isPopup: isPopup)
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isPopup ? focusGoalOpacity : 1)

            // Tips list
            VStack(spacing: 14) {
                ForEach(Array(task.tips.prefix(3).enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [theme.startColor, theme.endColor],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text(tip)
                            .font(.subheadline).foregroundStyle(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
            }
            .opacity(isPopup ? focusChipsOpacity : 1)
        }
        .padding(20).cardStyle()
    }

    // MARK: - Flow Section Card

    private let flowBadgeSize: CGFloat = 28

    private var flowSectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("学习流程").font(.subheadline.bold()).foregroundStyle(AppColors.primaryText)
                Spacer()
                Text("\(task.steps.count) steps")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(theme.startColor.opacity(0.08)).clipShape(Capsule())
            }

            VStack(spacing: 0) {
                ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                    let state = stepDisplayState(at: index)
                    if state != .hidden {
                        flowStepRow(step: step, index: index, state: state, isLast: index == task.steps.count - 1)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(16).cardStyle()
    }

    @ViewBuilder
    private func flowStepRow(step: LearningStep, index: Int, state: OverviewStepDisplayState, isLast: Bool) -> some View {
        let isAnimating = phase != .ready
        let isCompleted = progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index)
        let isTappable = phase == .ready && !showCenteredFlow && (state == .unlocked || isCompleted)

        HStack(alignment: .center, spacing: 12) {
            // Badge with connector line below, all in one column
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(AppColors.card).frame(width: flowBadgeSize + 2, height: flowBadgeSize + 2)
                    if isCompleted && !isAnimating {
                        Circle().fill(AppColors.success).frame(width: flowBadgeSize, height: flowBadgeSize)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    } else {
                        switch state {
                        case .hidden: EmptyView()
                        case .spinning:
                            StepSpinnerBadge(number: index + 1, color: step.type.color).frame(width: flowBadgeSize, height: flowBadgeSize)
                        case .checked:
                            Circle().fill(AppColors.success).frame(width: flowBadgeSize, height: flowBadgeSize)
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        case .unlocked:
                            Circle().fill(step.type.color.opacity(0.14)).frame(width: flowBadgeSize, height: flowBadgeSize)
                            Text("\(index + 1)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(step.type.color)
                        case .locked:
                            Circle().fill(AppColors.surface).frame(width: flowBadgeSize, height: flowBadgeSize)
                            Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                }
                .animation(.spring(duration: 0.4, bounce: 0.2), value: stepDisplayStates)

                // Connector line — part of the same VStack, no gap
                if !isLast {
                    Rectangle()
                        .fill(connectorColor(for: index))
                        .frame(width: 2, height: 14)
                }
            }

            // Text content — vertically centered with badge
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: step.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(stepTitleColor(for: step, index: index, state: state))
                    Text(stepTitleText(for: step, at: index))
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(AppColors.primaryText)
                }
                Text(stepSubtitleText(for: step, at: index, state: state))
                    .font(.system(size: 11)).foregroundStyle(AppColors.tertiaryText)
                    .lineLimit(1)
            }
            .opacity(state == .spinning ? 0.92 : 1)

            Spacer()

            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isTappable {
                tappedStepIndex = index
                showLearning = true
            }
        }
    }

    private func stepDisplayState(at index: Int) -> OverviewStepDisplayState {
        guard stepDisplayStates.indices.contains(index) else { return .hidden }
        return stepDisplayStates[index]
    }

    private func stepTitleColor(for step: LearningStep, index: Int, state: OverviewStepDisplayState) -> Color {
        if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) { return AppColors.success }
        switch state {
        case .locked: return AppColors.tertiaryText
        case .checked: return AppColors.success
        default: return step.type.color
        }
    }

    private func stepSubtitle(for step: LearningStep, state: OverviewStepDisplayState) -> String {
        state == .locked ? "完成前一步后解锁" : step.subtitle
    }

    private func stepTitleText(for step: LearningStep, at index: Int) -> String {
        guard showCenteredFlow, stepTextChars.indices.contains(index) else { return step.title }
        let chars = stepTextChars[index]
        guard chars < step.title.count else { return step.title }
        return chars > 0 ? String(step.title.prefix(chars)) : ""
    }

    private func stepSubtitleText(for step: LearningStep, at index: Int, state: OverviewStepDisplayState) -> String {
        let full = stepSubtitle(for: step, state: state)
        guard showCenteredFlow, stepTextChars.indices.contains(index) else { return full }
        let titleLen = step.title.count
        let chars = stepTextChars[index]
        let subtitleChars = max(0, chars - titleLen)
        guard subtitleChars < full.count else { return full }
        return subtitleChars > 0 ? String(full.prefix(subtitleChars)) : ""
    }

    private func connectorColor(for index: Int) -> Color {
        if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) { return AppColors.success.opacity(0.28) }
        switch stepDisplayState(at: index) {
        case .unlocked: return theme.startColor.opacity(0.22)
        case .checked: return AppColors.success.opacity(0.28)
        case .locked: return AppColors.border.opacity(0.45)
        case .spinning: return task.steps[index].type.color.opacity(0.2)
        case .hidden: return .clear
        }
    }

    // MARK: - Reveal Sequence

    @MainActor
    private func runRevealSequence() async {
        resetRevealState()

        // Skip animation for revisited tasks
        if hasSeenAnimation {
            skipToReady()
            return
        }

        // ========== HERO CARD POPUP ==========
        phase = .heroEntrance
        showCenteredHero = true
        withAnimation(.easeOut(duration: 0.35)) { darkOverlayOpacity = 0.85 }
        await pause(0.12)
        guard !Task.isCancelled else { return }

        withAnimation(.spring(duration: 0.85, bounce: 0.12)) {
            heroEntranceScale = 1.0; heroRotationX = 0; heroEntranceOpacity = 1
        }
        withAnimation(.easeInOut(duration: 1.2)) { glowIntensity = 1 }
        await pause(0.55)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.25)) { contentRevealProgress = 1 }
        await pause(0.2)
        guard !Task.isCancelled else { return }

        phase = .heroTitleReveal
        withAnimation(.spring(duration: 0.45, bounce: 0.08)) { heroTitleOpacity = 1 }
        await pause(0.25)
        guard !Task.isCancelled else { return }

        phase = .heroDescriptionReveal
        await typeHeroPrompt()
        await pause(0.1)
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.3)) { heroMetaOpacity = 1 }
        await pause(0.6)
        guard !Task.isCancelled else { return }

        // Hero dock — popup flies up, docked drops in
        phase = .heroDockToTop
        withAnimation(.easeIn(duration: 0.45)) {
            heroEntranceScale = 0.7
            heroPopupOffsetY = -200
            heroEntranceOpacity = 0
            glowIntensity = 0
        }
        withAnimation(.easeOut(duration: 0.4)) { darkOverlayOpacity = 0 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        showCenteredHero = false
        withAnimation(.spring(duration: 0.6, bounce: 0.12)) {
            showDockedHero = true
        }
        await pause(0.5)
        guard !Task.isCancelled else { return }

        // ========== FOCUS CARD POPUP ==========
        phase = .focusPopup
        showCenteredFocus = true
        withAnimation(.easeOut(duration: 0.3)) { darkOverlayOpacity = 0.72 }
        await pause(0.15)
        guard !Task.isCancelled else { return }

        // Focus card enters
        withAnimation(.spring(duration: 0.65, bounce: 0.12)) {
            focusPopupScale = 1.0; focusPopupOpacity = 1
        }
        await pause(0.3)
        guard !Task.isCancelled else { return }

        // Staggered content reveal — section by section
        withAnimation(.easeOut(duration: 0.4)) { focusContentOpacity = 1 }
        // Title row
        withAnimation(.easeOut(duration: 0.5)) { focusTitleOpacity = 1 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        // Goal / description — typewriter reveal
        focusGoalOpacity = 1
        await typeFocusGoal()
        await pause(0.25)
        guard !Task.isCancelled else { return }
        // Angle chips
        withAnimation(.easeOut(duration: 0.5)) { focusChipsOpacity = 1 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        // Stats
        withAnimation(.easeOut(duration: 0.5)) { focusStatsOpacity = 1 }
        await pause(0.35)
        guard !Task.isCancelled else { return }
        // Suggestion — typewriter reveal
        focusSuggestionOpacity = 1
        await typeFocusSuggestion()
        // Stabilization pause — give user time to read
        await pause(1.8)
        guard !Task.isCancelled else { return }

        // Focus dock — popup flies up, docked drops in
        phase = .focusDock
        withAnimation(.easeIn(duration: 0.45)) {
            focusPopupScale = 0.7
            focusPopupOffsetY = -200
            focusPopupOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.4)) { darkOverlayOpacity = 0 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        showCenteredFocus = false
        withAnimation(.spring(duration: 0.6, bounce: 0.12)) {
            showDockedFocus = true
        }
        await pause(0.5)
        guard !Task.isCancelled else { return }

        // ========== FLOW CARD POPUP (with step spinning) ==========
        phase = .flowPopup
        showCenteredFlow = true
        // Pre-init all steps as hidden so the card shell shows
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        stepTextChars = Array(repeating: 0, count: task.steps.count)

        withAnimation(.easeOut(duration: 0.3)) { darkOverlayOpacity = 0.72 }
        await pause(0.1)
        guard !Task.isCancelled else { return }

        // Flow card enters
        withAnimation(.spring(duration: 0.65, bounce: 0.12)) {
            flowPopupScale = 1.0; flowPopupOpacity = 1
        }
        await pause(0.35)
        guard !Task.isCancelled else { return }

        // Steps spin one by one with typewriter text
        phase = .flowStepSpin
        for index in task.steps.indices {
            guard !Task.isCancelled else { return }
            let step = task.steps[index]
            let subtitle = stepSubtitle(for: step, state: .spinning)
            let totalChars = step.title.count + subtitle.count

            // Start spinning + typewriter simultaneously
            let typeDuration = max(0.8, Double(totalChars) * 0.08)
            withAnimation(.spring(duration: 0.4, bounce: 0.16)) {
                stepDisplayStates[index] = .spinning
            }
            await typeStepText(index: index, totalChars: totalChars, duration: typeDuration)
            guard !Task.isCancelled else { return }
            // Reading pause — let user absorb
            await pause(0.5)
            guard !Task.isCancelled else { return }
            // Settle to checkmark
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                stepDisplayStates[index] = .checked
            }
            await pause(0.3)
        }
        guard !Task.isCancelled else { return }

        // Brief stabilization with all checkmarks visible
        await pause(0.8)
        guard !Task.isCancelled else { return }

        // Flow dock — popup flies up, docked drops in
        phase = .flowDock
        withAnimation(.easeIn(duration: 0.45)) {
            flowPopupScale = 0.7
            flowPopupOffsetY = -200
            flowPopupOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.4)) { darkOverlayOpacity = 0 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        showCenteredFlow = false
        withAnimation(.spring(duration: 0.6, bounce: 0.12)) {
            showDockedFlow = true
        }
        await pause(0.45)
        guard !Task.isCancelled else { return }
        // Switch from checkmarks to actual progress (locked/unlocked)
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            for index in task.steps.indices {
                stepDisplayStates[index] = settledStepState(for: index)
            }
        }
        await pause(0.3)
        guard !Task.isCancelled else { return }

        // Scroll flow card to visual center
        scrollToFlow = true
        await pause(0.5)
        guard !Task.isCancelled else { return }

        // ========== READY ==========
        phase = .ready
        markAnimationSeen()
    }

    private func skipToReady() {
        showDockedHero = true
        showDockedFocus = true
        showDockedFlow = true
        stepDisplayStates = task.steps.indices.map { settledStepState(for: $0) }
        stepTextChars = task.steps.map { $0.title.count + $0.subtitle.count }
        phase = .ready
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
        let totalDuration = min(1.0, max(0.5, Double(characters.count) * 0.02))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return }
            heroPromptChars = index + 1
            await pause(interval)
        }
    }

    @MainActor
    private func typeFocusGoal() async {
        let text: String
        if let lessonContent {
            text = lessonContent.topic.learningGoal ?? "先看思路，再学词汇和框架，最后对照范文开口练。"
        } else {
            text = "打开这道题时，先理解题意，再抓关键词，最后按照步骤开口练。"
        }
        let characters = Array(text)
        guard !characters.isEmpty else { return }

        // Start TTS playback of the learning goal while typing
        let playbackId = EnglishSpeechPlayer.playbackID(for: text, category: "focus-goal")
        EnglishSpeechPlayer.shared.togglePlayback(id: playbackId, text: text, sourceLabel: "学习重点")

        let totalDuration = min(2.5, max(1.0, Double(characters.count) * 0.045))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return }
            focusGoalChars = index + 1
            await pause(interval)
        }
    }

    @MainActor
    private func typeFocusSuggestion() async {
        let text = "先看答题思路，再学词汇和框架，最后对照范文开口练。"
        let characters = Array(text)
        guard !characters.isEmpty else { return }
        let totalDuration = min(1.2, max(0.5, Double(characters.count) * 0.035))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return }
            focusSuggestionChars = index + 1
            await pause(interval)
        }
    }

    @MainActor
    private func typeStepText(index: Int, totalChars: Int, duration: Double) async {
        guard totalChars > 0 else { return }
        let interval = duration / Double(totalChars)
        for charIdx in 0..<totalChars {
            guard !Task.isCancelled else { return }
            stepTextChars[index] = charIdx + 1
            await pause(interval)
        }
    }

    private func resetRevealState() {
        phase = .idle
        darkOverlayOpacity = 0
        // Hero
        showCenteredHero = false
        heroEntranceScale = 0.5; heroRotationX = 45; heroEntranceOpacity = 0
        heroPopupOffsetY = 0
        contentRevealProgress = 0; heroTitleOpacity = 0; heroPromptChars = 0; heroMetaOpacity = 0
        glowIntensity = 0
        // Focus
        showCenteredFocus = false
        focusPopupScale = 0.6; focusPopupOpacity = 0; focusContentOpacity = 0
        focusPopupOffsetY = 0
        focusTitleOpacity = 0; focusGoalOpacity = 0; focusGoalChars = 0; focusChipsOpacity = 0
        focusStatsOpacity = 0; focusSuggestionOpacity = 0; focusSuggestionChars = 0
        // Flow
        showCenteredFlow = false
        flowPopupScale = 0.6; flowPopupOpacity = 0; flowPopupOffsetY = 0
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        stepTextChars = Array(repeating: 0, count: task.steps.count)
        // Docked
        showDockedHero = false; showDockedFocus = false; showDockedFlow = false
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

}

// MARK: - Focus Audio Wave

private struct FocusAudioWaveView: View {
    let isActive: Bool
    let color: Color

    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2, height: isActive && animating ? barHeight(i) : 4)
                    .animation(
                        isActive
                            ? .easeInOut(duration: 0.4 + Double(i) * 0.15)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1)
                            : .easeOut(duration: 0.2),
                        value: animating
                    )
            }
        }
        .frame(width: 12, height: 14)
        .onChange(of: isActive) { _, active in
            animating = active
        }
        .onAppear { animating = isActive }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 8
        case 1: return 14
        default: return 10
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }
        return (CGSize(width: maxWidth, height: totalHeight), origins)
    }
}

// MARK: - Step Spinner Badge
struct StepSpinnerBadge: View {
    let number: Int
    let color: Color
    @State private var rotation: Double = 0
    @State private var numberVisible = false

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: 0.35)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.05), color], center: .center),
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
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(0.1)) { numberVisible = true }
        }
    }
}
