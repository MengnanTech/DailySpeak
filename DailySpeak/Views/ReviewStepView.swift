import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedAudioIds: Set<String> = []
    @State private var showReviewGuide = false
    @State private var reviewGuideStartIndex = 0
    @State private var reviewGuideEndIndex: Int? = nil
    @State private var reviewGuideCompleted = false
    private var lesson: LessonContent? { task.lessonContent }
    private let reviewColor = Color(hex: "F97316")

    private var requiredAudioIds: Set<String> {
        var ids: Set<String> = []
        if let lesson {
            for tip in lesson.strategy.highScoreTips {
                ids.insert(EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip"))
            }
            for mistake in lesson.strategy.commonMistakes.language {
                ids.insert(EnglishSpeechPlayer.playbackID(for: mistake.betterExample, category: "review-lang"))
            }
        }
        return ids
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "高分检查",
                    subtitle: "骨架搭好后，再查内容力度和语言自然度。",
                    englishTitle: "Score Check",
                    englishSubtitle: "After structuring, check content depth and naturalness.",
                    accentColor: reviewColor
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "checklist",
                    title: "高分检查",
                    english: "Score Check",
                    subtitle: "Quick check on content and language accuracy",
                    accentColor: reviewColor,
                    secondaryColor: Color(hex: "FB923C")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            if let lesson {
                lessonReviewContent(lesson)
            } else {
                standardReviewContent
            }
        }
        .onAppear {
            appeared = true
            updateReviewProgress()
            AudioPreloader.preloadStep(.review, task: task)
        }
        .onChange(of: listenedAudioIds.count) { _, _ in
            updateReviewProgress()
        }
        .onChange(of: reviewGuideCompleted) { _, _ in
            updateReviewProgress()
        }
        .fullScreenCover(isPresented: $showReviewGuide) {
            if let lesson {
                ReviewGuidedView(
                    lesson: lesson,
                    accentColor: reviewColor,
                    startIndex: reviewGuideStartIndex,
                    endIndex: reviewGuideEndIndex,
                    onComplete: { completedIds in
                        listenedAudioIds.formUnion(completedIds)
                        reviewGuideCompleted = true
                    }
                )
            }
        }
    }

    private func updateReviewProgress() {
        if lesson != nil {
            canComplete = reviewGuideCompleted
            progressHint = reviewGuideCompleted ? nil : "完成 Guide 学习"
        } else {
            let remaining = requiredAudioIds.subtracting(listenedAudioIds).count
            canComplete = remaining == 0
            progressHint = remaining == 0 ? nil : "听完标记项 \(requiredAudioIds.intersection(listenedAudioIds).count)/\(requiredAudioIds.count)"
        }
    }

    // MARK: - Standard Review

    private var standardReviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepSectionLabel(
                icon: "checklist.checked",
                title: "Final Check Before Speaking",
                color: reviewColor
            )

            ForEach(Array(task.tips.enumerated()), id: \.offset) { _, tip in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        HStack(spacing: 6) {
                            CompactPlayButton(
                                text: tip,
                                playbackID: EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip"),
                                sourceLabel: "Review Tip",
                                accentColor: reviewColor
                            )
                            TranslateButton(englishText: tip, accentColor: reviewColor, showInline: false)
                        }
                    }
                    TranslationOverlay(englishText: tip, accentColor: reviewColor)
                }
                .padding(10)
                .background(reviewColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(18)
        .cardStyle()
        .staggerIn(index: 1, appeared: appeared)
    }

    // MARK: - Lesson Review

    private func lessonReviewContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // High-score tips
            let tipCount = lesson.strategy.highScoreTips.count
            let contentCount = lesson.strategy.commonMistakes.content.count
            let langCount = lesson.strategy.commonMistakes.language.count
            let totalItems = tipCount + contentCount + langCount

            HStack {
                Text("\(totalItems) Review Items")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(reviewColor)
                Spacer()

                GuideButton(isCompleted: reviewGuideCompleted, accentColor: reviewColor, label: "Guide All") {
                    reviewGuideStartIndex = 0
                    reviewGuideEndIndex = nil
                    showReviewGuide = true
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            // High-score tips section
            let tipTexts = lesson.strategy.highScoreTips
            let allTipsText = tipTexts.joined(separator: ". ")
            let allTipsPlaybackId = EnglishSpeechPlayer.playbackID(for: allTipsText, category: "review-tips-all")

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(reviewColor)
                Text("High Score Tips")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(reviewColor)

                Spacer()
                HStack(spacing: 6) {
                    GuideButton(isCompleted: reviewGuideCompleted, accentColor: reviewColor) {
                        reviewGuideStartIndex = 0
                        reviewGuideEndIndex = tipCount
                        showReviewGuide = true
                    }

                    if reviewGuideCompleted {
                        CompactPlayButton(
                            text: allTipsText,
                            playbackID: allTipsPlaybackId,
                            sourceLabel: "Review Tips",
                            accentColor: reviewColor,
                            onPlay: {
                                for tip in tipTexts {
                                    listenedAudioIds.insert(EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip"))
                                }
                            }
                        )
                        BatchTranslateButton(texts: tipTexts, accentColor: reviewColor)
                    }
                }
                .fixedSize()
            }
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tipTexts.enumerated()), id: \.offset) { index, tip in
                    let tipPlayId = EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(reviewColor)
                                .clipShape(Circle())

                            Text(tip)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)

                            if reviewGuideCompleted {
                                Spacer()
                                CompactPlayButton(
                                    text: tip,
                                    playbackID: tipPlayId,
                                    sourceLabel: "Review Tip",
                                    accentColor: reviewColor,
                                    onPlay: { listenedAudioIds.insert(tipPlayId) }
                                )
                            }
                        }

                        TranslationOverlay(englishText: tip, accentColor: reviewColor)
                    }
                }
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(reviewColor.opacity(0.3))
            )
            .staggerIn(index: 3, appeared: appeared)

            // Content mistakes section
            let mistakeColor = Color(hex: "EF4444")
            let contentFieldTexts = lesson.strategy.commonMistakes.content.flatMap { [$0.problem, $0.whyItHurts, $0.fix] }
            let allContentText = lesson.strategy.commonMistakes.content.map { "\($0.problem). \($0.whyItHurts). \($0.fix)" }.joined(separator: " ")
            let contentPlaybackId = EnglishSpeechPlayer.playbackID(for: allContentText, category: "review-content-all")

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(mistakeColor)
                Text("Content Pitfalls")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(mistakeColor)

                Spacer()
                HStack(spacing: 6) {
                    GuideButton(isCompleted: reviewGuideCompleted, accentColor: mistakeColor) {
                        reviewGuideStartIndex = tipCount
                        reviewGuideEndIndex = tipCount + contentCount
                        showReviewGuide = true
                    }

                    if reviewGuideCompleted {
                        CompactPlayButton(
                            text: allContentText,
                            playbackID: contentPlaybackId,
                            sourceLabel: "Content Pitfalls",
                            accentColor: mistakeColor
                        )
                        BatchTranslateButton(texts: contentFieldTexts, accentColor: mistakeColor)
                    }
                }
                .fixedSize()
            }
            .staggerIn(index: 4, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(lesson.strategy.commonMistakes.content.enumerated()), id: \.element.problem) { _, mistake in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)
                        TranslationOverlay(englishText: mistake.problem, accentColor: mistakeColor)

                        (
                            Text("Why it hurts  ")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(mistakeColor.opacity(0.82))
                            + Text(mistake.whyItHurts)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        TranslationOverlay(englishText: mistake.whyItHurts, accentColor: mistakeColor)

                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.success)
                                .padding(.top, 3)
                            Text(mistake.fix)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        TranslationOverlay(englishText: mistake.fix, accentColor: AppColors.success)

                        if mistake.problem != lesson.strategy.commonMistakes.content.last?.problem {
                            Divider().background(AppColors.border.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(mistakeColor.opacity(0.3))
            )
            .staggerIn(index: 5, appeared: appeared)

            // Language corrections section
            let langColor = Color(hex: "8B5CF6")
            let langFieldTexts = lesson.strategy.commonMistakes.language.flatMap { [$0.problem, $0.wrongExample, $0.betterExample, $0.reason] }
            let allLangText = lesson.strategy.commonMistakes.language.map { "\($0.problem). \($0.wrongExample). \($0.betterExample). \($0.reason)" }.joined(separator: " ")
            let langPlaybackId = EnglishSpeechPlayer.playbackID(for: allLangText, category: "review-lang-all")

            HStack(spacing: 8) {
                Image(systemName: "textformat.abc")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(langColor)
                Text("Language Fix")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(langColor)

                Spacer()
                HStack(spacing: 6) {
                    GuideButton(isCompleted: reviewGuideCompleted, accentColor: langColor) {
                        reviewGuideStartIndex = tipCount + contentCount
                        reviewGuideEndIndex = tipCount + contentCount + langCount
                        showReviewGuide = true
                    }

                    if reviewGuideCompleted {
                        CompactPlayButton(
                            text: allLangText,
                            playbackID: langPlaybackId,
                            sourceLabel: "Language Fix",
                            accentColor: langColor,
                            onPlay: {
                                for m in lesson.strategy.commonMistakes.language {
                                    listenedAudioIds.insert(EnglishSpeechPlayer.playbackID(for: m.betterExample, category: "review-lang"))
                                }
                            }
                        )
                        BatchTranslateButton(texts: langFieldTexts, accentColor: langColor)
                    }
                }
                .fixedSize()
            }
            .staggerIn(index: 6, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(lesson.strategy.commonMistakes.language.enumerated()), id: \.element.problem) { _, mistake in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                        TranslationOverlay(englishText: mistake.problem, accentColor: langColor)

                        HStack(alignment: .top, spacing: 8) {
                            Text("Wrong")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(mistakeColor)
                            Text(mistake.wrongExample)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.tertiaryText)
                                .strikethrough(color: mistakeColor.opacity(0.4))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        TranslationOverlay(englishText: mistake.wrongExample, accentColor: mistakeColor)

                        let betterPlayId = EnglishSpeechPlayer.playbackID(for: mistake.betterExample, category: "review-lang")
                        HStack(alignment: .top, spacing: 8) {
                            Text("Better")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.success)
                            Text(mistake.betterExample)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            if reviewGuideCompleted {
                                Spacer()
                                CompactPlayButton(
                                    text: mistake.betterExample,
                                    playbackID: betterPlayId,
                                    sourceLabel: "Better Example",
                                    accentColor: langColor,
                                    onPlay: { listenedAudioIds.insert(betterPlayId) }
                                )
                            }
                        }
                        TranslationOverlay(englishText: mistake.betterExample, accentColor: AppColors.success)

                        Text(mistake.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        TranslationOverlay(englishText: mistake.reason, accentColor: langColor)

                        if mistake.problem != lesson.strategy.commonMistakes.language.last?.problem {
                            Divider().background(AppColors.border.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [8, 5]))
                    .foregroundStyle(langColor.opacity(0.3))
            )
            .staggerIn(index: 7, appeared: appeared)
        }
    }
}

// MARK: - Review Guided View (Immersive)

private enum ReviewGuideItem: Identifiable {
    case tip(index: Int, text: String)
    case contentMistake(index: Int, mistake: LessonContent.Strategy.ContentMistake)
    case languageMistake(index: Int, mistake: LessonContent.Strategy.LanguageMistake)

    var id: String {
        switch self {
        case .tip(let i, _): "tip-\(i)"
        case .contentMistake(let i, _): "content-\(i)"
        case .languageMistake(let i, _): "lang-\(i)"
        }
    }

    var sectionColor: Color {
        switch self {
        case .tip: Color(hex: "F97316")
        case .contentMistake: Color(hex: "EF4444")
        case .languageMistake: Color(hex: "8B5CF6")
        }
    }

    var sectionIcon: String {
        switch self {
        case .tip: "sparkles"
        case .contentMistake: "exclamationmark.triangle.fill"
        case .languageMistake: "textformat.abc"
        }
    }

    var sectionLabel: String {
        switch self {
        case .tip: "High Score Tip"
        case .contentMistake: "Content Pitfall"
        case .languageMistake: "Language Fix"
        }
    }

    /// The text used for TTS playback
    var playableText: String {
        switch self {
        case .tip(_, let text): text
        case .contentMistake(_, let m): "\(m.problem). \(m.fix)"
        case .languageMistake(_, let m): m.betterExample
        }
    }

    var playbackCategory: String {
        switch self {
        case .tip: "review-tip"
        case .contentMistake: "review-content"
        case .languageMistake: "review-lang"
        }
    }

    var playbackID: String {
        EnglishSpeechPlayer.playbackID(for: playableText, category: playbackCategory)
    }
}

private struct ReviewGuidedView: View {
    let lesson: LessonContent
    let accentColor: Color
    var startIndex: Int = 0
    var endIndex: Int? = nil
    var onComplete: (Set<String>) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex: Int

    init(lesson: LessonContent, accentColor: Color, startIndex: Int = 0, endIndex: Int? = nil, onComplete: @escaping (Set<String>) -> Void = { _ in }) {
        self.lesson = lesson
        self.accentColor = accentColor
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.onComplete = onComplete
        self._currentIndex = State(initialValue: 0)
    }
    @State private var audioFinished = false
    @State private var completedAudioIds: Set<String> = []
    @State private var allDone = false

    private var items: [ReviewGuideItem] {
        var all: [ReviewGuideItem] = []
        for (i, tip) in lesson.strategy.highScoreTips.enumerated() {
            all.append(.tip(index: i, text: tip))
        }
        for (i, m) in lesson.strategy.commonMistakes.content.enumerated() {
            all.append(.contentMistake(index: i, mistake: m))
        }
        for (i, m) in lesson.strategy.commonMistakes.language.enumerated() {
            all.append(.languageMistake(index: i, mistake: m))
        }
        let end = endIndex ?? all.count
        return Array(all[startIndex..<end])
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

                    // Section badge
                    if !allDone {
                        let item = items[currentIndex]
                        HStack(spacing: 5) {
                            Image(systemName: item.sectionIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(item.sectionLabel)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(item.sectionColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(item.sectionColor.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(currentIndex + 1) / \(items.count)")
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
                            .fill(allDone ? accentColor : items[currentIndex].sectionColor)
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                let item = items[currentIndex]
                                let pid = item.playbackID
                                if !player.isPlaying(id: pid) {
                                    player.togglePlayback(id: pid, text: item.playableText, sourceLabel: item.sectionLabel)
                                }
                            }
                        }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(accentColor)
                        Text("Score Check Complete!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Ready to speak!")
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
            let currentPid = items[currentIndex].playbackID
            if oldValue == currentPid && newValue == nil && player.pausedPlaybackID != currentPid {
                withAnimation { audioFinished = true }
                completedAudioIds.insert(currentPid)
            }
        }
        .task {
            let preloadItems: [AudioPreloader.AudioItem] = items.map { item in
                (id: item.playbackID, text: item.playableText)
            }
            await EnglishSpeechPlayer.shared.preloadBatch(preloadItems)
        }
        .background(ClearBackgroundView())
    }

    @ViewBuilder
    private func cardForItem(_ item: ReviewGuideItem) -> some View {
        let color = item.sectionColor
        let pid = item.playbackID

        VStack(alignment: .leading, spacing: 16) {
            switch item {
            case .tip(let index, let text):
                // Header
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(color)
                        .clipShape(Circle())
                    Text("High Score Tip")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Spacer()
                }

                Text(text)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                TranslationOverlay(englishText: text, accentColor: color)

            case .contentMistake(_, let mistake):
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(color)
                        .clipShape(Circle())
                    Text("Content Pitfall")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Spacer()
                }

                // Problem
                Text(mistake.problem)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                TranslationOverlay(englishText: mistake.problem, accentColor: color)

                // Why it hurts
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why it hurts")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color.opacity(0.82))
                    Text(mistake.whyItHurts)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                TranslationOverlay(englishText: mistake.whyItHurts, accentColor: color)

                // Fix
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.success)
                        .padding(.top, 2)
                    Text(mistake.fix)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                TranslationOverlay(englishText: mistake.fix, accentColor: AppColors.success)

            case .languageMistake(_, let mistake):
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(color)
                        .clipShape(Circle())
                    Text("Language Fix")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Spacer()
                }

                // Problem title
                Text(mistake.problem)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                TranslationOverlay(englishText: mistake.problem, accentColor: color)

                // Wrong vs Better
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("WRONG")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "EF4444"))
                            .clipShape(Capsule())
                        Text(mistake.wrongExample)
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.tertiaryText)
                            .strikethrough(color: Color(hex: "EF4444").opacity(0.4))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Text("BETTER")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.success)
                            .clipShape(Capsule())
                        Text(mistake.betterExample)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                TranslationOverlay(englishText: "\(mistake.wrongExample) → \(mistake.betterExample)", accentColor: color)

                // Reason
                Text(mistake.reason)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                TranslationOverlay(englishText: mistake.reason, accentColor: color)
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

                let translateTexts: [String] = {
                    switch item {
                    case .tip(_, let text): return [text]
                    case .contentMistake(_, let m): return [m.problem, m.whyItHurts, m.fix]
                    case .languageMistake(_, let m): return [m.problem, "\(m.wrongExample) → \(m.betterExample)", m.reason]
                    }
                }()
                BatchTranslateButton(texts: translateTexts, accentColor: color)
            }

            // Navigation buttons
            HStack(spacing: 12) {
                if currentIndex > 0 {
                    Button {
                        player.stopPlayback()
                        if currentIndex > 0 {
                            withAnimation {
                                currentIndex -= 1
                                audioFinished = false
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .bold))
                            Text("Back")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

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
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
    }

    private func advanceToNext() {
        player.stopPlayback()
        let currentPid = items[currentIndex].playbackID
        completedAudioIds.insert(currentPid)

        if currentIndex < items.count - 1 {
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

// MARK: - Batch Translate Button
/// One button in header that translates multiple texts individually,
/// so each item can show its own TranslationOverlay.
struct BatchTranslateButton: View {
    let texts: [String]
    var accentColor: Color = .blue

    @State private var cache = TranslationCache.shared
    @State private var isLoading = false

    private var allVisible: Bool {
        texts.allSatisfy { cache.visibleKeys.contains($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 12, weight: .medium))
                }
                Text(allVisible ? "收起" : "翻译")
                    .font(.system(size: 12, weight: .medium))
            }
            .fixedSize()
            .foregroundStyle(allVisible ? .white : accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(allVisible ? accentColor : accentColor.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func handleTap() {
        if allVisible {
            // Hide all
            for text in texts {
                cache.visibleKeys.remove(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return
        }
        // Translate all and show
        isLoading = true
        Task {
            await withTaskGroup(of: Void.self) { group in
                for text in texts {
                    group.addTask {
                        _ = try? await cache.translate(text)
                    }
                }
            }
            for text in texts {
                cache.visibleKeys.insert(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            isLoading = false
        }
    }
}

// Helper for transparent fullScreenCover background
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
