import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var listenedAudioIds: Set<String> = []
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
            VStack(alignment: .leading, spacing: 12) {
                StepSectionLabel(icon: "sparkles", title: "高分提醒", color: reviewColor)

                ForEach(Array(lesson.strategy.highScoreTips.enumerated()), id: \.offset) { _, tip in
                    let playbackId = EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip")
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        HStack(spacing: 8) {
                            InlineAudioPlayerControl(
                                text: tip,
                                playbackID: playbackId,
                                sourceLabel: "Review Tip",
                                accentColor: reviewColor,
                                style: .compact,
                                onPlay: { listenedAudioIds.insert(playbackId) }
                            )
                            TranslateButton(englishText: tip, accentColor: reviewColor)
                        }
                    }
                    .padding(10)
                    .background(reviewColor.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 1, appeared: appeared)

            // Content mistakes
            VStack(alignment: .leading, spacing: 14) {
                StepSectionLabel(
                    icon: "exclamationmark.triangle.fill",
                    title: "内容避坑",
                    color: Color(hex: "EF4444")
                )

                ForEach(Array(lesson.strategy.commonMistakes.content.enumerated()), id: \.element.problem) { _, mistake in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)

                        (
                            Text("Why it hurts  ")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "EF4444").opacity(0.82))
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

                        TranslateButton(englishText: "\(mistake.problem). \(mistake.fix)", accentColor: Color(hex: "EF4444"))

                        if mistake.problem != lesson.strategy.commonMistakes.content.last?.problem {
                            Divider().background(AppColors.border.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 2, appeared: appeared)

            // Language corrections
            VStack(alignment: .leading, spacing: 14) {
                StepSectionLabel(
                    icon: "textformat.abc",
                    title: "语言修正",
                    color: Color(hex: "8B5CF6")
                )

                ForEach(Array(lesson.strategy.commonMistakes.language.enumerated()), id: \.element.problem) { index, mistake in
                    let playbackId = EnglishSpeechPlayer.playbackID(for: mistake.betterExample, category: "review-lang")
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

                        HStack(alignment: .top, spacing: 8) {
                            Text("Wrong")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "EF4444"))
                            Text(mistake.wrongExample)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.tertiaryText)
                                .strikethrough(color: Color(hex: "EF4444").opacity(0.4))
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

                        InlineAudioPlayerControl(
                            text: mistake.betterExample,
                            playbackID: playbackId,
                            sourceLabel: "Review Language",
                            accentColor: Color(hex: "8B5CF6"),
                            style: .compact,
                            onPlay: { listenedAudioIds.insert(playbackId) }
                        )

                        Text(mistake.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        TranslateButton(englishText: "\(mistake.wrongExample) → \(mistake.betterExample). \(mistake.reason)", accentColor: Color(hex: "8B5CF6"))

                        if mistake.problem != lesson.strategy.commonMistakes.language.last?.problem {
                            Divider().background(AppColors.border.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 3, appeared: appeared)
        }
    }
}
