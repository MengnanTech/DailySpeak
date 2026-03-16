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
    @State private var focusVisibleAngleCount: Int = 0
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
    @State private var revealTask: Task<Void, Never>?

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
        .onAppear {
            revealTask = Task { await runRevealSequence() }
        }
        .onDisappear {
            revealTask?.cancel()
            revealTask = nil
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
                    Text("Key Focus")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text(lesson.practice.targetLength)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                Spacer()
                if phase == .ready && !showCenteredFocus {
                    HStack(spacing: 6) {
                        let goalText = lesson.topic.learningGoal ?? "Start with strategy, then learn vocabulary and framework, finally practice with samples."
                        let anglesText = lesson.strategy.angles.enumerated().map { "\($0.offset + 1). \($0.element.title)" }.joined(separator: ". ")
                        let fullText = goalText + " " + anglesText
                        CompactPlayButton(
                            text: fullText,
                            playbackID: EnglishSpeechPlayer.playbackID(for: fullText, category: "focus-goal"),
                            sourceLabel: "Key Focus",
                            accentColor: theme.startColor
                        )
                        TranslateButton(englishText: goalText, accentColor: theme.startColor, showInline: false)
                    }
                }
            }
            .opacity(isPopup ? focusTitleOpacity : 1)

            // Learning goal with accent bar + typewriter
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [theme.startColor, theme.endColor],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                let goalText = lesson.topic.learningGoal ?? "Start with strategy, then learn vocabulary and framework, finally practice with samples."
                let goalKey = goalText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !isPopup, TranslationCache.shared.visibleKeys.contains(goalKey), let chinese = TranslationCache.shared.cached(goalKey) {
                    Text(chinese)
                        .font(.subheadline).foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    focusGoalText(goalText, isPopup: isPopup)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isPopup ? focusGoalOpacity : 1)

            // Angle chips — vertical list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lesson.strategy.angles.enumerated()), id: \.element.title) { index, angle in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(theme.startColor)
                            .clipShape(Circle())
                        Text(angle.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                    }
                    .opacity(isPopup ? (index < focusVisibleAngleCount ? 1 : 0) : 1)
                    .offset(y: isPopup ? (index < focusVisibleAngleCount ? 0 : 10) : 0)
                }
            }
            .opacity(isPopup ? focusChipsOpacity : 1)

            // Stats row — card-style mini stats
            HStack(spacing: 0) {
                lessonMiniStat(title: "Strategy", value: "\(lesson.strategy.angles.count)", icon: "sparkles")
                miniStatDivider
                lessonMiniStat(title: "Vocab", value: "\(task.vocabulary.count)", icon: "textformat.abc")
                miniStatDivider
                lessonMiniStat(title: "Samples", value: "\(task.sampleAnswers.count)", icon: "doc.text")
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.startColor.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .opacity(isPopup ? focusStatsOpacity : 1)

            // Suggestion section with typewriter — highlighted card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.startColor)
                    Text("Suggested Order")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.startColor)
                }
                focusSuggestionText("Start with strategy, then learn vocabulary and framework, finally practice with samples.", isPopup: isPopup)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.startColor.opacity(0.06))
            )
            .opacity(isPopup ? focusSuggestionOpacity : 1)
        }
        .padding(20).cardStyle()
    }

    private var miniStatDivider: some View {
        Rectangle()
            .fill(AppColors.border)
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

    private func lessonMiniStat(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.startColor.opacity(0.7))
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
                    Text("Key Focus")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text(task.suggestedTime)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                Spacer()
                if phase == .ready && !showCenteredFocus {
                    HStack(spacing: 6) {
                        let fallbackGoal = "Understand the topic first, identify key words, then follow the steps to practice speaking."
                        CompactPlayButton(
                            text: fallbackGoal,
                            playbackID: EnglishSpeechPlayer.playbackID(for: fallbackGoal, category: "focus-goal"),
                            sourceLabel: "Key Focus",
                            accentColor: theme.startColor
                        )
                        TranslateButton(englishText: fallbackGoal, accentColor: theme.startColor, showInline: false)
                    }
                }
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
                let fbGoal = "Understand the topic first, identify key words, then follow the steps to practice speaking."
                let fbKey = fbGoal.trimmingCharacters(in: .whitespacesAndNewlines)
                if !isPopup, TranslationCache.shared.visibleKeys.contains(fbKey), let chinese = TranslationCache.shared.cached(fbKey) {
                    Text(chinese)
                        .font(.subheadline).foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    focusGoalText(fbGoal, isPopup: isPopup)
                }
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

    @State private var flowTranslationCache = TranslationCache.shared

    private var allStepTexts: [String] {
        task.steps.map { step in
            step.title + ". " + step.subtitle
        }
    }

    private var flowSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Learning Flow").font(.subheadline.bold()).foregroundStyle(AppColors.primaryText)
                Spacer()
                if showCenteredFlow {
                    Button {
                        revealTask?.cancel()
                        revealTask = nil
                        showCenteredHero = false
                        showCenteredFocus = false
                        showCenteredFlow = false
                        darkOverlayOpacity = 0
                        skipToReady()
                        markAnimationSeen()
                    } label: {
                        Text("跳过")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                } else if phase == .ready {
                    HStack(spacing: 6) {
                        let allText = allStepTexts.joined(separator: ". ")
                        CompactPlayButton(
                            text: allText,
                            playbackID: EnglishSpeechPlayer.playbackID(for: allText, category: "flow-all"),
                            sourceLabel: "Learning Flow",
                            accentColor: theme.startColor
                        )
                        BatchTranslateButton(texts: allStepTexts, accentColor: theme.startColor)
                    }
                }
            }
            .padding(.bottom, 2)

            VStack(spacing: 0) {
                ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                    let state = stepDisplayState(at: index)
                    let isLast = index == task.steps.count - 1
                    if state != .hidden {
                        flowStepRow(step: step, index: index, state: state, isLast: isLast)
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
        HStack(alignment: .top, spacing: 12) {
            // Badge + connector in one column
            VStack(spacing: 0) {
                ZStack {
                    if isCompleted && !isAnimating {
                        Circle().fill(AppColors.success).frame(width: 28, height: 28)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    } else {
                        switch state {
                        case .hidden: EmptyView()
                        case .spinning:
                            StepSpinnerBadge(number: index + 1, color: step.type.color).frame(width: 28, height: 28)
                        case .checked:
                            Circle().fill(AppColors.success).frame(width: 28, height: 28)
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                        case .unlocked:
                            Circle().fill(step.type.color.opacity(0.14)).frame(width: 28, height: 28)
                            Text("\(index + 1)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(step.type.color)
                        case .locked:
                            Circle().fill(AppColors.surface).frame(width: 28, height: 28)
                            Image(systemName: "lock.fill").font(.system(size: 10)).foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                }
                .animation(.spring(duration: 0.4, bounce: 0.2), value: stepDisplayStates)

                if !isLast {
                    Rectangle()
                        .fill(connectorColor(for: index))
                        .frame(width: 2, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                let stepKey = (step.title + ". " + step.subtitle).trimmingCharacters(in: .whitespacesAndNewlines)
                let isTranslated = flowTranslationCache.visibleKeys.contains(stepKey)
                let translatedText = flowTranslationCache.cached(stepKey)

                HStack(spacing: 6) {
                    Image(systemName: step.icon).font(.system(size: 12, weight: .bold))
                        .foregroundStyle(stepTitleColor(for: step, index: index, state: state))
                    Text(stepTitleText(for: step, at: index))
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(AppColors.primaryText)
                }
                if isTranslated, let translated = translatedText {
                    Text(translated)
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(stepSubtitleText(for: step, at: index, state: state))
                        .font(.system(size: 13)).foregroundStyle(AppColors.tertiaryText)
                }
            }
            .opacity(state == .spinning ? 0.92 : 1)
            Spacer()
            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(maxHeight: .infinity, alignment: .center)
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
        step.subtitle
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
        let heroPid = await typeHeroPrompt()
        // Wait for hero prompt audio to finish
        if let pid = heroPid {
            await waitForPlaybackToFinish(pid: pid, timeout: 15)
        }
        await pause(0.5)
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
        // Goal / description — typewriter reveal + wait for audio
        focusGoalOpacity = 1
        let focusGoalPid = await typeFocusGoal()
        // Wait for focus-goal audio to finish playing
        if let pid = focusGoalPid {
            await waitForPlaybackToFinish(pid: pid, timeout: 15)
        }
        await pause(0.5)
        guard !Task.isCancelled else { return }
        // Angle chips — reveal one by one with TTS
        withAnimation(.easeOut(duration: 0.3)) { focusChipsOpacity = 1 }
        if let lesson = lessonContent {
            EnglishSpeechPlayer.shared.stopPlayback()
            for (index, angle) in lesson.strategy.angles.enumerated() {
                guard !Task.isCancelled else { return }
                let pid = EnglishSpeechPlayer.playbackID(for: angle.title, category: "focus-angle")
                withAnimation(.spring(duration: 0.35, bounce: 0.12)) {
                    focusVisibleAngleCount = index + 1
                }
                EnglishSpeechPlayer.shared.togglePlayback(id: pid, text: angle.title, sourceLabel: "Focus Angle")
                await waitForPlaybackToFinish(pid: pid, timeout: 8)
                await pause(0.3)
            }
        } else {
            focusVisibleAngleCount = 100
            await pause(0.4)
        }
        guard !Task.isCancelled else { return }
        // Stats
        withAnimation(.easeOut(duration: 0.5)) { focusStatsOpacity = 1 }
        await pause(0.35)
        guard !Task.isCancelled else { return }
        // Suggestion — typewriter reveal
        focusSuggestionOpacity = 1
        let suggestionPid = await typeFocusSuggestion()
        // Wait for suggestion audio to finish
        if let pid = suggestionPid {
            await waitForPlaybackToFinish(pid: pid, timeout: 15)
        }
        // Stabilization pause — give user time to read
        await pause(0.8)
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

            // Stop any previous step TTS
            EnglishSpeechPlayer.shared.stopPlayback()
            // Start spinning + typewriter + TTS simultaneously
            let typeDuration = max(0.6, Double(totalChars) * 0.04)
            withAnimation(.spring(duration: 0.35, bounce: 0.16)) {
                stepDisplayStates[index] = .spinning
            }
            // Speak step title during typewriter animation
            let stepFullText = step.title + ". " + subtitle
            let pid = EnglishSpeechPlayer.playbackID(for: stepFullText, category: "step-overview")
            EnglishSpeechPlayer.shared.togglePlayback(id: pid, text: stepFullText, sourceLabel: "Step Overview")
            await typeStepText(index: index, totalChars: totalChars, duration: typeDuration)
            guard !Task.isCancelled else { return }
            // Wait for audio to finish playing before moving on
            await waitForPlaybackToFinish(pid: pid, timeout: 10)
            guard !Task.isCancelled else { return }
            // Brief reading pause after audio finishes
            await pause(0.5)
            guard !Task.isCancelled else { return }
            // Settle to checkmark
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                stepDisplayStates[index] = .checked
            }
            await pause(0.2)
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
        EnglishSpeechPlayer.shared.stopPlayback()
        showDockedHero = true
        showDockedFocus = true
        showDockedFlow = true
        focusVisibleAngleCount = 100
        stepDisplayStates = task.steps.indices.map { settledStepState(for: $0) }
        stepTextChars = task.steps.map { $0.title.count + $0.subtitle.count }
        phase = .ready
        // Scroll to Learning Flow card after layout settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            scrollToFlow = true
        }
    }

    private func settledStepState(for index: Int) -> OverviewStepDisplayState {
        let currentStep = currentUnlockedStepIndex
        if currentStep >= task.steps.count { return .unlocked }
        return index <= currentStep ? .unlocked : .locked
    }

    @MainActor
    private func typeHeroPrompt() async -> String? {
        let characters = Array(task.prompt)
        guard !characters.isEmpty else { return nil }

        // Play TTS synced with typewriter
        let playbackId = EnglishSpeechPlayer.playbackID(for: task.prompt, category: "hero-prompt")
        EnglishSpeechPlayer.shared.togglePlayback(id: playbackId, text: task.prompt, sourceLabel: "Topic")

        let audioDuration = EnglishSpeechPlayer.shared.cachedDuration(id: playbackId)
        let totalDuration = audioDuration ?? min(1.0, max(0.5, Double(characters.count) * 0.02))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return playbackId }
            heroPromptChars = index + 1
            await pause(interval)
        }
        return playbackId
    }

    @MainActor
    private func typeFocusGoal() async -> String? {
        let text: String
        if let lessonContent {
            text = lessonContent.topic.learningGoal ?? "Start with strategy, then learn vocabulary and framework, finally practice with samples."
        } else {
            text = "Understand the topic first, identify key words, then follow the steps to practice speaking."
        }
        let characters = Array(text)
        guard !characters.isEmpty else { return nil }

        // Play TTS — audio was pre-loaded in TaskLoadingView, plays from local file instantly
        let playbackId = EnglishSpeechPlayer.playbackID(for: text, category: "focus-goal")
        EnglishSpeechPlayer.shared.togglePlayback(id: playbackId, text: text, sourceLabel: "Key Focus")

        // Match typewriter duration to actual audio duration
        let audioDuration = EnglishSpeechPlayer.shared.cachedDuration(id: playbackId)
        let totalDuration = audioDuration ?? min(2.5, max(1.2, Double(characters.count) * 0.045))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return playbackId }
            focusGoalChars = index + 1
            await pause(interval)
        }
        return playbackId
    }

    @MainActor
    private func typeFocusSuggestion() async -> String? {
        let text = "Start with strategy, then learn vocabulary and framework, finally practice with samples."
        let characters = Array(text)
        guard !characters.isEmpty else { return nil }

        // Play TTS synced with typewriter
        let playbackId = EnglishSpeechPlayer.playbackID(for: text, category: "focus-suggestion")
        EnglishSpeechPlayer.shared.togglePlayback(id: playbackId, text: text, sourceLabel: "Key Focus")

        let audioDuration = EnglishSpeechPlayer.shared.cachedDuration(id: playbackId)
        let totalDuration = audioDuration ?? min(1.2, max(0.5, Double(characters.count) * 0.035))
        let interval = totalDuration / Double(characters.count)
        for index in characters.indices {
            guard !Task.isCancelled else { return playbackId }
            focusSuggestionChars = index + 1
            await pause(interval)
        }
        return playbackId
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
        focusTitleOpacity = 0; focusGoalOpacity = 0; focusGoalChars = 0; focusChipsOpacity = 0; focusVisibleAngleCount = 0
        focusStatsOpacity = 0; focusSuggestionOpacity = 0; focusSuggestionChars = 0
        // Flow
        showCenteredFlow = false
        flowPopupScale = 0.6; flowPopupOpacity = 0; flowPopupOffsetY = 0
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        stepTextChars = Array(repeating: 0, count: task.steps.count)
        // Docked
        showDockedHero = false; showDockedFocus = false; showDockedFlow = false
    }

    /// Wait until the given playback ID finishes (activePlaybackID becomes nil), with a timeout.
    @MainActor
    private func waitForPlaybackToFinish(pid: String, timeout: Double) async {
        let player = EnglishSpeechPlayer.shared
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            guard !Task.isCancelled else { return }
            // Audio finished or was never started
            if player.activePlaybackID != pid && player.loadingPlaybackID != pid {
                return
            }
            await pause(0.15)
        }
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
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
