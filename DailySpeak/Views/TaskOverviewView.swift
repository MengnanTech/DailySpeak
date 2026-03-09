import SwiftUI

struct TaskOverviewView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var showLearning = false
    @State private var showCriteria = false
    @State private var appear = false

    // Strategy tip sequential animation states
    @State private var visibleTipCount = 0      // How many tips are visible
    @State private var completedTips = Set<Int>() // Which tips have the checkmark
    @State private var currentLoadingTip: Int? = nil // Which tip is showing spinner
    @State private var tipDisplayedChars: [Int: Int] = [:] // How many characters shown per tip

    // Steps timeline sequential animation states
    @State private var visibleStepCount = 0
    @State private var completedSteps = Set<Int>()
    @State private var currentLoadingStep: Int? = nil
    @State private var stepTitleChars: [Int: Int] = [:]
    @State private var stepSubtitleChars: [Int: Int] = [:]

    private var theme: StageTheme { stage.theme }
    private var lessonContent: LessonContent? { task.lessonContent }

    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let lessonContent {
                            lessonBanner(lessonContent)
                            lessonSummaryCard(lessonContent)
                            lessonModulesCard
                        } else {
                            topBanner
                            strategyCard
                            stepsTimeline
                        }
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

    private func lessonBanner(_ lesson: LessonContent) -> some View {
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

                        Text(task.prompt)
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
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
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

    private var lessonModulesCard: some View {
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

            VStack(spacing: 10) {
                ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(theme.startColor.opacity(0.12))
                                    .frame(width: 28, height: 28)
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.startColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                Text(step.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }

                            Spacer()
                        }

                        if index < task.steps.count - 1 {
                            Divider().background(AppColors.border)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .cardStyle()
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

                if completedTips.count == task.tips.count {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Done")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.success.opacity(0.1))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Tips")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "F59E0B"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "FEF3C7"))
                        .clipShape(Capsule())
                }
            }

            // Tips with timeline animation
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                    if index < visibleTipCount {
                        let isLast = index == task.tips.count - 1
                        let isDone = completedTips.contains(index)

                        HStack(alignment: .top, spacing: 12) {
                            // Left: indicator + connector line
                            VStack(spacing: 0) {
                                ZStack {
                                    if isDone {
                                        Circle()
                                            .fill(AppColors.success)
                                            .frame(width: 22, height: 22)
                                            .transition(.scale)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .transition(.scale)
                                    } else if currentLoadingTip == index {
                                        TipSpinnerView()
                                            .frame(width: 22, height: 22)
                                            .transition(.scale)
                                    } else {
                                        Circle()
                                            .strokeBorder(Color(hex: "F59E0B").opacity(0.3), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                .animation(.spring(duration: 0.4, bounce: 0.2), value: completedTips)
                                .animation(.spring(duration: 0.3), value: currentLoadingTip)

                                if !isLast {
                                    // Connector line
                                    Rectangle()
                                        .fill(
                                            isDone
                                                ? AppColors.success.opacity(0.25)
                                                : Color(hex: "F59E0B").opacity(0.12)
                                        )
                                        .frame(width: 1.5)
                                        .frame(maxHeight: .infinity)
                                        .animation(.easeOut(duration: 0.35), value: isDone)
                                }
                            }
                            .frame(width: 22)

                            // Right: tip text
                            VStack(alignment: .leading, spacing: 0) {
                                if let charCount = tipDisplayedChars[index], charCount > 0 {
                                    Text(String(tip.prefix(charCount)))
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            isDone ? AppColors.primaryText : AppColors.secondText
                                        )
                                        .fixedSize(horizontal: false, vertical: true)
                                        .animation(.none, value: charCount)
                                }
                            }
                            .padding(.bottom, isLast ? 0 : 16)
                            .padding(.top, 2)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        .onAppear { startTipSequence() }
    }

    // MARK: - Tip Sequence Animation
    private func startTipSequence() {
        animateTip(at: 0, afterDelay: 0.6)
    }

    private func animateTip(at index: Int, afterDelay delay: Double) {
        guard index < task.tips.count else { return }
        let tip = task.tips[index]
        let charInterval: Double = 0.04 // seconds per character

        // Step 1: Show the row with spinner
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                visibleTipCount = index + 1
                currentLoadingTip = index
            }

            // Step 2: Typewriter — one character at a time
            for charIndex in 1...tip.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(charIndex) * charInterval) {
                    tipDisplayedChars[index] = charIndex
                }
            }

            // Step 3: Complete with checkmark after all characters are typed
            let typingDuration = 0.3 + Double(tip.count) * charInterval + 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + typingDuration) {
                withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                    completedTips.insert(index)
                    if index == task.tips.count - 1 {
                        currentLoadingTip = nil
                    }
                }

                // Start next tip after a brief pause
                animateTip(at: index + 1, afterDelay: 0.3)
            }
        }
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

                if completedSteps.count == task.steps.count {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Done")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.success.opacity(0.1))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                } else {
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
            }
            .padding(.bottom, 16)

            ForEach(Array(task.steps.enumerated()), id: \.element.id) { index, step in
                if index < visibleStepCount {
                    let isLast = index == task.steps.count - 1
                    let isAnimDone = completedSteps.contains(index)

                    HStack(alignment: .top, spacing: 14) {
                        // Left: indicator + connector line
                        VStack(spacing: 0) {
                            ZStack {
                                if isAnimDone {
                                    Circle().fill(AppColors.success)
                                        .frame(width: 28, height: 28)
                                        .transition(.scale)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .transition(.scale)
                                } else if currentLoadingStep == index {
                                    TipSpinnerView()
                                        .frame(width: 28, height: 28)
                                        .transition(.scale)
                                } else {
                                    Circle()
                                        .strokeBorder(AppColors.border, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .animation(.spring(duration: 0.4, bounce: 0.2), value: completedSteps)
                            .animation(.spring(duration: 0.3), value: currentLoadingStep)

                            if !isLast {
                                Rectangle()
                                    .fill(isAnimDone ? AppColors.success.opacity(0.3) : AppColors.border.opacity(0.5))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                                    .animation(.easeOut(duration: 0.3), value: isAnimDone)
                            }
                        }
                        .frame(width: 28)

                        // Right: title + subtitle typewriter
                        VStack(alignment: .leading, spacing: 3) {
                            if let titleChars = stepTitleChars[index], titleChars > 0 {
                                Text(String(step.title.prefix(titleChars)))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(
                                        isAnimDone ? AppColors.primaryText : AppColors.secondText
                                    )
                                    .animation(.none, value: titleChars)
                            }

                            if let subChars = stepSubtitleChars[index], subChars > 0 {
                                Text(String(step.subtitle.prefix(subChars)))
                                    .font(.caption)
                                    .foregroundStyle(AppColors.tertiaryText)
                                    .animation(.none, value: subChars)
                            }
                        }
                        .padding(.bottom, isLast ? 0 : 20)
                        .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        .onAppear { startStepSequence() }
    }

    // MARK: - Step Sequence Animation
    private func startStepSequence() {
        // Wait for tips to finish first
        let tipsCount = task.tips.count
        let tipCharInterval: Double = 0.04
        var totalTipsDuration: Double = 0.6
        for i in 0..<tipsCount {
            let tipLen = Double(task.tips[i].count)
            totalTipsDuration += 0.3 + tipLen * tipCharInterval + 0.3 + 0.3
        }
        animateStep(at: 0, afterDelay: totalTipsDuration + 0.3)
    }

    private func animateStep(at index: Int, afterDelay delay: Double) {
        guard index < task.steps.count else { return }
        let step = task.steps[index]
        let charInterval: Double = 0.05

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Show row with spinner
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                visibleStepCount = index + 1
                currentLoadingStep = index
            }

            // Typewriter: title first
            let title = step.title
            for ci in 1...title.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(ci) * charInterval) {
                    stepTitleChars[index] = ci
                }
            }

            // Then subtitle
            let subtitle = step.subtitle
            let subtitleStart = 0.25 + Double(title.count) * charInterval + 0.1
            for ci in 1...subtitle.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + subtitleStart + Double(ci) * charInterval) {
                    stepSubtitleChars[index] = ci
                }
            }

            // Checkmark after all text typed
            let totalTyping = subtitleStart + Double(subtitle.count) * charInterval + 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + totalTyping) {
                withAnimation(.spring(duration: 0.4, bounce: 0.25)) {
                    completedSteps.insert(index)
                    if index == task.steps.count - 1 {
                        currentLoadingStep = nil
                    }
                }
                animateStep(at: index + 1, afterDelay: 0.25)
            }
        }
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

// MARK: - Tip Spinner View
struct TipSpinnerView: View {
    @State private var rotation: Double = 0

    private let amber = Color(hex: "F59E0B")

    var body: some View {
        ZStack {
            // Faint track ring
            Circle()
                .stroke(amber.opacity(0.12), lineWidth: 2)

            // Fixed-length gradient arc, smooth forward rotation
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [amber.opacity(0.05), amber],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
