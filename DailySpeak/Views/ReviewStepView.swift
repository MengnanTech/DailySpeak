import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedAudioIds: Set<String> = []
    @State private var showReviewGuide = false
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
                    accentColor: reviewColor
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "checklist",
                    title: "高分检查",
                    english: "Score Check",
                    subtitle: "答完前快速检查内容完整度和语言准确度",
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
        }
        .onChange(of: listenedAudioIds.count) { _, _ in
            updateReviewProgress()
        }
        .fullScreenCover(isPresented: $showReviewGuide) {
            if let lesson {
                ReviewGuidedView(
                    lesson: lesson,
                    accentColor: reviewColor,
                    onComplete: { completedIds in
                        listenedAudioIds.formUnion(completedIds)
                    }
                )
            }
        }
    }

    private func updateReviewProgress() {
        let remaining = requiredAudioIds.subtracting(listenedAudioIds).count
        if remaining == 0 {
            canComplete = true
            progressHint = nil
        } else {
            canComplete = false
            progressHint = "还剩 \(remaining) 个语音未听"
        }
    }

    // MARK: - Standard Review

    private var standardReviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepSectionLabel(
                icon: "checklist.checked",
                title: "开口前，最后检查",
                color: reviewColor
            )

            ForEach(Array(task.tips.enumerated()), id: \.offset) { _, tip in
                VStack(alignment: .leading, spacing: 8) {
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)

                    TranslateButton(englishText: tip, accentColor: reviewColor)
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

                Button {
                    showReviewGuide = true
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
                    .background(reviewColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .staggerIn(index: 1, appeared: appeared)

            // High-score tips section
            let allTipsText = lesson.strategy.highScoreTips.joined(separator: ". ")
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
                    CompactPlayButton(
                        text: allTipsText,
                        playbackID: allTipsPlaybackId,
                        sourceLabel: "Review Tips",
                        accentColor: reviewColor,
                        onPlay: { listenedAudioIds.insert(allTipsPlaybackId) }
                    )
                    TranslateButton(englishText: allTipsText, accentColor: reviewColor, showInline: false)
                }
            }
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(lesson.strategy.highScoreTips.enumerated()), id: \.offset) { index, tip in
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
                    }
                }

                TranslationOverlay(englishText: allTipsText, accentColor: reviewColor)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(mistakeColor)
                    Text("Content Pitfalls")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(mistakeColor)
                }

                ForEach(Array(lesson.strategy.commonMistakes.content.enumerated()), id: \.element.problem) { _, mistake in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)

                        (
                            Text("Why it hurts  ")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(mistakeColor.opacity(0.82))
                            + Text(mistake.whyItHurts)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        )
                        .fixedSize(horizontal: false, vertical: true)

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

                        TranslateButton(englishText: "\(mistake.problem). \(mistake.fix)", accentColor: mistakeColor, showInline: false)
                        TranslationOverlay(englishText: "\(mistake.problem). \(mistake.fix)", accentColor: mistakeColor)

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
            .staggerIn(index: 4, appeared: appeared)

            // Language corrections section
            let langColor = Color(hex: "8B5CF6")
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(langColor)
                    Text("Language Fix")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(langColor)
                }

                ForEach(Array(lesson.strategy.commonMistakes.language.enumerated()), id: \.element.problem) { _, mistake in
                    let playbackId = EnglishSpeechPlayer.playbackID(for: mistake.betterExample, category: "review-lang")
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

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

                        HStack(alignment: .top, spacing: 8) {
                            Text("Better")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.success)
                            Text(mistake.betterExample)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 8) {
                            CompactPlayButton(
                                text: mistake.betterExample,
                                playbackID: playbackId,
                                sourceLabel: "Review Language",
                                accentColor: langColor,
                                onPlay: { listenedAudioIds.insert(playbackId) }
                            )
                            TranslateButton(
                                englishText: "\(mistake.wrongExample) → \(mistake.betterExample). \(mistake.reason)",
                                accentColor: langColor,
                                showInline: false
                            )
                        }

                        Text(mistake.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        TranslationOverlay(
                            englishText: "\(mistake.wrongExample) → \(mistake.betterExample). \(mistake.reason)",
                            accentColor: langColor
                        )

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
            .staggerIn(index: 5, appeared: appeared)
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
    var onComplete: (Set<String>) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var currentIndex = 0
    @State private var audioFinished = false
    @State private var completedAudioIds: Set<String> = []
    @State private var allDone = false

    private var items: [ReviewGuideItem] {
        var result: [ReviewGuideItem] = []
        for (i, tip) in lesson.strategy.highScoreTips.enumerated() {
            result.append(.tip(index: i, text: tip))
        }
        for (i, m) in lesson.strategy.commonMistakes.content.enumerated() {
            result.append(.contentMistake(index: i, mistake: m))
        }
        for (i, m) in lesson.strategy.commonMistakes.language.enumerated() {
            result.append(.languageMistake(index: i, mistake: m))
        }
        return result
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                        Text("高分检查已完成！")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("准备开口说吧")
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
                VStack(alignment: .leading, spacing: 6) {
                    Text(mistake.problem)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    TranslateButton(englishText: mistake.problem, accentColor: color)
                    TranslationOverlay(englishText: mistake.problem, accentColor: color)
                }

                // Why it hurts
                VStack(alignment: .leading, spacing: 6) {
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

                    TranslateButton(englishText: mistake.whyItHurts, accentColor: color)
                    TranslationOverlay(englishText: mistake.whyItHurts, accentColor: color)
                }

                // Fix
                VStack(alignment: .leading, spacing: 6) {
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
                    TranslateButton(englishText: mistake.fix, accentColor: AppColors.success)
                    TranslationOverlay(englishText: mistake.fix, accentColor: AppColors.success)
                }

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
                VStack(alignment: .leading, spacing: 6) {
                    Text(mistake.problem)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                    TranslateButton(englishText: mistake.problem, accentColor: color)
                    TranslationOverlay(englishText: mistake.problem, accentColor: color)
                }

                // Wrong vs Better
                VStack(alignment: .leading, spacing: 8) {
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

                    TranslateButton(englishText: "\(mistake.wrongExample) → \(mistake.betterExample)", accentColor: color)
                    TranslationOverlay(englishText: "\(mistake.wrongExample) → \(mistake.betterExample)", accentColor: color)
                }

                // Reason
                VStack(alignment: .leading, spacing: 6) {
                    Text(mistake.reason)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                    TranslateButton(englishText: mistake.reason, accentColor: color)
                    TranslationOverlay(englishText: mistake.reason, accentColor: color)
                }
            }

            // Audio player
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
            }

            // Tip type: keep shared translate for the whole text
            if case .tip = item {
                TranslateButton(englishText: item.playableText, accentColor: color, showInline: false)
                TranslationOverlay(englishText: item.playableText, accentColor: color)
            }

            // Confirm button
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
