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
    @State private var phase: OverviewPresentationPhase = .idle

    // Dark overlay (shared by all popups)
    @State private var darkOverlayOpacity: Double = 0

    // --- Hero card popup ---
    @State private var showCenteredHero = false
    @State private var heroEntranceScale: CGFloat = 0.5
    @State private var heroRotationX: Double = 45
    @State private var heroEntranceOpacity: Double = 0
    @State private var heroDockOffsetY: CGFloat = 0
    @State private var heroDockScale: CGFloat = 1.0
    @State private var heroDockOpacity: Double = 1.0
    @State private var contentRevealProgress: Double = 0
    @State private var heroTitleOpacity: Double = 0
    @State private var heroPromptChars = 0
    @State private var heroMetaOpacity: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    // --- Focus card popup ---
    @State private var showCenteredFocus = false
    @State private var focusPopupScale: CGFloat = 0.6
    @State private var focusPopupOpacity: Double = 0
    @State private var focusContentOpacity: Double = 0
    @State private var focusDockOffsetY: CGFloat = 0
    @State private var focusDockScale: CGFloat = 1.0
    @State private var focusDockOpacity: Double = 1.0
    // Focus staggered reveal
    @State private var focusTitleOpacity: Double = 0
    @State private var focusGoalOpacity: Double = 0
    @State private var focusChipsOpacity: Double = 0
    @State private var focusStatsOpacity: Double = 0
    @State private var focusSuggestionOpacity: Double = 0

    // --- Flow card popup ---
    @State private var showCenteredFlow = false
    @State private var flowPopupScale: CGFloat = 0.6
    @State private var flowPopupOpacity: Double = 0
    @State private var flowDockOffsetY: CGFloat = 0
    @State private var flowDockScale: CGFloat = 1.0
    @State private var flowDockOpacity: Double = 1.0
    @State private var stepDisplayStates: [OverviewStepDisplayState] = []

    // --- Docked content ---
    @State private var showDockedHero = false
    @State private var showDockedFocus = false
    @State private var showDockedFlow = false

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

    private var centeredHeroCardWidth: CGFloat {
        min(UIScreen.main.bounds.width - 48, 420)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable docked content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if showDockedHero {
                        dockedCardContent
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    if showDockedFocus {
                        focusSectionCard
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    if showDockedFlow {
                        flowSectionCard
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    Color.clear.frame(height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDisabled(phase != .ready)

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
                    ZStack {
                        Ellipse()
                            .fill(RadialGradient(
                                colors: [theme.startColor.opacity(0.28), theme.endColor.opacity(0.08), .clear],
                                center: .center, startRadius: 30, endRadius: 220
                            ))
                            .frame(width: 360, height: 280)
                            .blur(radius: 50)
                            .opacity(glowIntensity)

                        centeredCardContent
                            .padding(.horizontal, 24)
                            .shadow(color: theme.startColor.opacity(0.35 * glowIntensity), radius: 28, x: 0, y: 12)
                    }
                    .scaleEffect(heroEntranceScale * heroDockScale)
                    .rotation3DEffect(.degrees(heroRotationX), axis: (x: 1, y: 0, z: 0), perspective: 0.7)
                    .opacity(heroEntranceOpacity * heroDockOpacity)
                    .offset(y: heroDockOffsetY)
                }
            }

            // Focus popup overlay
            if showCenteredFocus {
                popupOverlay {
                    focusSectionCard
                        .padding(.horizontal, 24)
                        .opacity(focusContentOpacity)
                        .shadow(color: theme.startColor.opacity(0.2), radius: 20, x: 0, y: 8)
                        .scaleEffect(focusPopupScale * focusDockScale)
                        .opacity(focusPopupOpacity * focusDockOpacity)
                        .offset(y: focusDockOffsetY)
                }
            }

            // Flow popup overlay
            if showCenteredFlow {
                popupOverlay {
                    flowSectionCard
                        .padding(.horizontal, 24)
                        .shadow(color: theme.startColor.opacity(0.2), radius: 20, x: 0, y: 8)
                        .scaleEffect(flowPopupScale * flowDockScale)
                        .opacity(flowPopupOpacity * flowDockOpacity)
                        .offset(y: flowDockOffsetY)
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
            LearningFlowView(stage: stage, task: task)
        }
        .task(id: task.id) {
            await runRevealSequence()
        }
    }

    // Shared popup container
    private func popupOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            Spacer()
            content()
            Spacer()
        }
        .zIndex(10)
    }

    // MARK: - Centered Hero Card (Theme-Colored Premium Reveal)

    private var centeredCardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        if let lessonContent {
                            revealChip(lessonContent.topic.stageLabel, delay: 0)
                            revealChip("Q\(String(format: "%02d", task.id))", delay: 0.05)
                        } else {
                            revealChip("Stage \(stage.id)", delay: 0)
                        }
                        revealChip(task.questionType, delay: 0.1)
                    }
                    Text(task.title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .opacity(heroTitleOpacity)
                    Text(task.englishTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .opacity(heroTitleOpacity)
                }
                Spacer(minLength: 8)
                ZStack {
                    Text(theme.emoji).font(.system(size: 42)).blur(radius: 12).opacity(0.4)
                    Text(theme.emoji).font(.system(size: 42))
                }
                .opacity(heroTitleOpacity)
            }
            .padding(.bottom, 18)

            Rectangle()
                .fill(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.5)
                .padding(.bottom, 16)
                .opacity(heroTitleOpacity)

            centeredHeroPromptBlock

            if let lessonContent {
                HStack(spacing: 8) {
                    metaPill(icon: "clock", text: lessonContent.practice.targetLength)
                    metaPill(icon: "doc.text", text: "\(task.sampleAnswers.count) samples")
                    metaPill(icon: "textformat.abc", text: "\(task.vocabulary.count) vocab")
                }
                .opacity(heroMetaOpacity)
            }
        }
        .padding(24)
        .frame(width: centeredHeroCardWidth, alignment: .leading)
        .background(centeredCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(centeredCardBorder)
        .overlay(centeredCardShimmer)
    }

    private var centeredCardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [theme.startColor.opacity(0.85), theme.startColor, theme.endColor.opacity(0.9)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            GeometryReader { geo in
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.18), .clear], center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 160, height: 160)
                    .offset(x: geo.size.width - 60, y: -40)
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.1), .clear], center: .center, startRadius: 0, endRadius: 50))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height - 30)
                Ellipse()
                    .fill(RadialGradient(colors: [theme.endColor.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 100))
                    .frame(width: 200, height: 140)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.5)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var centeredHeroPromptBlock: some View {
        ZStack(alignment: .topLeading) {
            Text(task.prompt)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hidden()

            Text(heroPromptText)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(heroPromptChars > 0 ? 1 : 0)
        }
        .padding(.bottom, 18)
    }

    private var centeredCardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(
                LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.12), .white.opacity(0.06), .white.opacity(0.15)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.8
            )
    }

    private var centeredCardShimmer: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [.clear, .white.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing))
            .offset(x: shimmerOffset)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .allowsHitTesting(false)
    }

    private func revealChip(_ text: String, delay: Double) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .textCase(.uppercase).tracking(0.5)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
            .opacity(contentRevealProgress > delay ? 1 : 0)
    }

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Docked Hero Card

    private var dockedCardContent: some View {
        Group {
            if let lessonContent {
                dockedLessonBanner(lessonContent)
            } else {
                dockedSimpleBanner
            }
        }
    }

    private var dockedSimpleBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(theme.softGradient)
            GeometryReader { geo in
                Circle().fill(.white.opacity(0.1)).frame(width: 80).offset(x: geo.size.width - 50, y: -15)
                Circle().fill(.white.opacity(0.06)).frame(width: 50).offset(x: -15, y: 55)
            }
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) { lessonChip("Stage \(stage.id)"); lessonChip(task.questionType) }
                    Text(task.title).font(.title3.bold()).foregroundStyle(.white)
                    Text(task.englishTitle).font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 10)
                Text(theme.emoji).font(.system(size: 34))
            }
            .padding(18)
        }
        .frame(height: 125).heroShadow()
    }

    private func dockedLessonBanner(_ lesson: LessonContent) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(theme.softGradient)
            GeometryReader { geo in
                Circle().fill(.white.opacity(0.12)).frame(width: 120).offset(x: geo.size.width - 70, y: -30)
                Circle().fill(.white.opacity(0.08)).frame(width: 64).offset(x: -10, y: 92)
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            lessonChip(lesson.topic.stageLabel)
                            lessonChip("Q\(String(format: "%02d", task.id))")
                            lessonChip(task.questionType)
                        }
                        Text(task.title).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text(task.prompt).font(.subheadline).foregroundStyle(.white.opacity(0.82)).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 12)
                    Text(theme.emoji).font(.system(size: 40))
                }
                HStack(spacing: 10) {
                    lessonMetaPill(icon: "clock.fill", text: lesson.practice.targetLength)
                    lessonMetaPill(icon: "text.quote", text: "\(task.sampleAnswers.count) samples")
                    lessonMetaPill(icon: "books.vertical.fill", text: "\(task.vocabulary.count) vocab")
                }
            }
            .padding(20)
        }
        .frame(minHeight: 190).heroShadow()
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
                    Text("学习重点")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text(lesson.practice.targetLength)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                Spacer()
            }
            .opacity(isPopup ? focusTitleOpacity : 1)

            // Learning goal with accent bar
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [theme.startColor, theme.endColor],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                Text(lesson.topic.learningGoal ?? "先看思路，再学词汇和框架，最后对照范文开口练。")
                    .font(.subheadline).foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isPopup ? focusGoalOpacity : 1)

            // Angle chips — improved style
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lesson.strategy.angles, id: \.title) { angle in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(theme.startColor)
                                .frame(width: 5, height: 5)
                            Text(angle.title)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.startColor)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(theme.startColor.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }
            .opacity(isPopup ? focusChipsOpacity : 1)

            // Stats row — card-style mini stats
            HStack(spacing: 0) {
                lessonMiniStat(title: "思路", value: "\(lesson.strategy.angles.count)", icon: "sparkles")
                miniStatDivider
                lessonMiniStat(title: "词汇", value: "\(task.vocabulary.count)", icon: "textformat.abc")
                miniStatDivider
                lessonMiniStat(title: "范文", value: "\(task.sampleAnswers.count)", icon: "doc.text")
            }
            .padding(.vertical, 10)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isPopup ? focusStatsOpacity : 1)

            // Suggestion section
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.startColor)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text("建议顺序")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.startColor)
                    Text("先看答题思路，再学词汇和框架，最后对照范文开口练。")
                        .font(.subheadline).foregroundStyle(AppColors.primaryText)
                }
            }
            .opacity(isPopup ? focusSuggestionOpacity : 1)
        }
        .padding(20).cardStyle()
    }

    private var miniStatDivider: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(width: 0.5, height: 28)
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

            // Description with accent bar
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(colors: [theme.startColor, theme.endColor],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3)
                Text("打开这道题时，先理解题意，再抓关键词，最后按照步骤开口练。")
                    .font(.subheadline).foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var flowSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("学习流程").font(.subheadline.bold()).foregroundStyle(AppColors.primaryText)
                Spacer()
                Text("\(task.steps.count) steps")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.startColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(theme.startColor.opacity(0.08)).clipShape(Capsule())
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
                                .frame(width: 2, height: 18)
                                .padding(.leading, 15).padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(18).cardStyle()
    }

    @ViewBuilder
    private func flowStepRow(step: LearningStep, index: Int, state: OverviewStepDisplayState) -> some View {
        let isTappable = phase == .ready && !showCenteredFlow && (state == .unlocked || progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index))
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                if progress.isStepCompleted(stageId: stage.id, taskId: task.id, stepIndex: index) {
                    Circle().fill(AppColors.success).frame(width: 30, height: 30)
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                } else {
                    switch state {
                    case .hidden: EmptyView()
                    case .spinning:
                        StepSpinnerBadge(number: index + 1, color: step.type.color).frame(width: 30, height: 30)
                    case .checked:
                        Circle().fill(AppColors.success).frame(width: 30, height: 30)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    case .unlocked:
                        Circle().fill(step.type.color.opacity(0.14)).frame(width: 30, height: 30)
                        Text("\(index + 1)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(step.type.color)
                    case .locked:
                        Circle().fill(AppColors.surface).frame(width: 30, height: 30)
                        Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(AppColors.tertiaryText)
                    }
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.2), value: stepDisplayStates)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: step.icon).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(stepTitleColor(for: step, index: index, state: state))
                    Text(step.title).font(.subheadline.bold()).foregroundStyle(AppColors.primaryText)
                }
                Text(stepSubtitle(for: step, state: state)).font(.caption).foregroundStyle(AppColors.tertiaryText)
            }
            .opacity(state == .spinning ? 0.92 : 1)
            Spacer()
            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if isTappable { showLearning = true }
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

        withAnimation(.easeInOut(duration: 0.8)) { shimmerOffset = 400 }
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

        // Hero dock — simultaneous crossfade
        phase = .heroDockToTop
        withAnimation(.spring(duration: 0.75, bounce: 0.06)) {
            heroDockOffsetY = -300; heroDockScale = 0.6; heroDockOpacity = 0; glowIntensity = 0
            showDockedHero = true
        }
        withAnimation(.easeOut(duration: 0.5)) { darkOverlayOpacity = 0 }
        await pause(0.7)
        guard !Task.isCancelled else { return }
        showCenteredHero = false

        // ========== FOCUS CARD POPUP ==========
        phase = .focusPopup
        showCenteredFocus = true
        withAnimation(.easeOut(duration: 0.3)) { darkOverlayOpacity = 0.72 }
        await pause(0.1)
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
        // Goal / description
        withAnimation(.easeOut(duration: 0.6)) { focusGoalOpacity = 1 }
        await pause(0.45)
        guard !Task.isCancelled else { return }
        // Angle chips
        withAnimation(.easeOut(duration: 0.5)) { focusChipsOpacity = 1 }
        await pause(0.4)
        guard !Task.isCancelled else { return }
        // Stats
        withAnimation(.easeOut(duration: 0.5)) { focusStatsOpacity = 1 }
        await pause(0.35)
        guard !Task.isCancelled else { return }
        // Suggestion
        withAnimation(.easeOut(duration: 0.5)) { focusSuggestionOpacity = 1 }
        // Stabilization pause — give user time to read
        await pause(2.5)
        guard !Task.isCancelled else { return }

        // Focus dock — simultaneous crossfade
        phase = .focusDock
        withAnimation(.spring(duration: 0.75, bounce: 0.06)) {
            focusDockOffsetY = -280; focusDockScale = 0.65; focusDockOpacity = 0
            showDockedFocus = true
        }
        withAnimation(.easeOut(duration: 0.5)) { darkOverlayOpacity = 0 }
        await pause(0.7)
        guard !Task.isCancelled else { return }
        showCenteredFocus = false

        // ========== FLOW CARD POPUP (with step spinning) ==========
        phase = .flowPopup
        showCenteredFlow = true
        // Pre-init all steps as hidden so the card shell shows
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)

        withAnimation(.easeOut(duration: 0.3)) { darkOverlayOpacity = 0.72 }
        await pause(0.1)
        guard !Task.isCancelled else { return }

        // Flow card enters
        withAnimation(.spring(duration: 0.65, bounce: 0.12)) {
            flowPopupScale = 1.0; flowPopupOpacity = 1
        }
        await pause(0.35)
        guard !Task.isCancelled else { return }

        // Steps spin one by one, each becomes checkmark when done
        phase = .flowStepSpin
        for index in task.steps.indices {
            guard !Task.isCancelled else { return }
            // Start spinning
            withAnimation(.spring(duration: 0.4, bounce: 0.16)) {
                stepDisplayStates[index] = .spinning
            }
            await pause(0.6)
            guard !Task.isCancelled else { return }
            // Settle to checkmark
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                stepDisplayStates[index] = .checked
            }
            await pause(0.2)
        }
        guard !Task.isCancelled else { return }

        // Brief stabilization with all checkmarks visible
        await pause(0.8)
        guard !Task.isCancelled else { return }

        // Flow dock — simultaneous crossfade
        phase = .flowDock
        withAnimation(.spring(duration: 0.75, bounce: 0.06)) {
            flowDockOffsetY = -280; flowDockScale = 0.65; flowDockOpacity = 0
            showDockedFlow = true
        }
        withAnimation(.easeOut(duration: 0.5)) { darkOverlayOpacity = 0 }
        await pause(0.7)
        guard !Task.isCancelled else { return }
        showCenteredFlow = false
        // Switch from checkmarks to actual progress (locked/unlocked)
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            for index in task.steps.indices {
                stepDisplayStates[index] = settledStepState(for: index)
            }
        }
        await pause(0.3)
        guard !Task.isCancelled else { return }

        // ========== READY ==========
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

    private func resetRevealState() {
        phase = .idle
        darkOverlayOpacity = 0
        // Hero
        showCenteredHero = false
        heroEntranceScale = 0.5; heroRotationX = 45; heroEntranceOpacity = 0
        heroDockOffsetY = 0; heroDockScale = 1.0; heroDockOpacity = 1.0
        contentRevealProgress = 0; heroTitleOpacity = 0; heroPromptChars = 0; heroMetaOpacity = 0
        glowIntensity = 0; shimmerOffset = -200
        // Focus
        showCenteredFocus = false
        focusPopupScale = 0.6; focusPopupOpacity = 0; focusContentOpacity = 0
        focusDockOffsetY = 0; focusDockScale = 1.0; focusDockOpacity = 1.0
        focusTitleOpacity = 0; focusGoalOpacity = 0; focusChipsOpacity = 0
        focusStatsOpacity = 0; focusSuggestionOpacity = 0
        // Flow
        showCenteredFlow = false
        flowPopupScale = 0.6; flowPopupOpacity = 0
        flowDockOffsetY = 0; flowDockScale = 1.0; flowDockOpacity = 1.0
        stepDisplayStates = Array(repeating: .hidden, count: task.steps.count)
        // Docked
        showDockedHero = false; showDockedFocus = false; showDockedFlow = false
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
