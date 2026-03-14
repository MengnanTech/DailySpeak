import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color
    @Binding var canComplete: Bool
    @Binding var progressHint: String?

    @State private var appeared = false
    @State private var checkedItems: Set<Int> = []
    @State private var listenedExamples: Set<Int> = []
    private var lesson: LessonContent? { task.lessonContent }
    private let reviewColor = Color(hex: "F97316")

    private var totalLanguageExamples: Int {
        lesson?.strategy.commonMistakes.language.count ?? 0
    }

    private var totalCheckItems: Int {
        if let lesson {
            return lesson.strategy.highScoreTips.count
                + lesson.strategy.commonMistakes.content.count
                + lesson.strategy.commonMistakes.language.count
        } else {
            return task.tips.count
        }
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
        .onChange(of: checkedItems.count) { _, _ in
            updateReviewProgress()
        }
        .onChange(of: listenedExamples.count) { _, _ in
            updateReviewProgress()
        }
    }

    private func updateReviewProgress() {
        let total = totalCheckItems
        let checked = checkedItems.count
        let langTotal = totalLanguageExamples
        let langListened = listenedExamples.count
        if checked >= total && langListened >= langTotal {
            canComplete = true
            progressHint = nil
        } else if langListened < langTotal {
            canComplete = false
            progressHint = "还剩 \(langTotal - langListened) 个语言修正未听"
        } else {
            canComplete = false
            progressHint = "还剩 \(total - checked) 项未勾选"
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

            ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        if checkedItems.contains(index) {
                            checkedItems.remove(index)
                        } else {
                            checkedItems.insert(index)
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: checkedItems.contains(index) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(checkedItems.contains(index) ? AppColors.success : AppColors.tertiaryText)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(checkedItems.contains(index) ? AppColors.tertiaryText : AppColors.secondText)
                            .strikethrough(checkedItems.contains(index))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .cardStyle()
        .staggerIn(index: 1, appeared: appeared)
    }

    // MARK: - Lesson Review

    private func lessonCheckIndex(section: Int, item: Int) -> Int {
        // section 0 = highScoreTips, 1 = content mistakes, 2 = language mistakes
        switch section {
        case 0: return item
        case 1: return (lesson?.strategy.highScoreTips.count ?? 0) + item
        default: return (lesson?.strategy.highScoreTips.count ?? 0) + (lesson?.strategy.commonMistakes.content.count ?? 0) + item
        }
    }

    private func lessonReviewContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // High-score tips
            VStack(alignment: .leading, spacing: 12) {
                StepSectionLabel(icon: "sparkles", title: "高分提醒", color: reviewColor)

                ForEach(Array(lesson.strategy.highScoreTips.enumerated()), id: \.offset) { index, tip in
                    let checkIdx = lessonCheckIndex(section: 0, item: index)
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            if checkedItems.contains(checkIdx) {
                                checkedItems.remove(checkIdx)
                            } else {
                                checkedItems.insert(checkIdx)
                            }
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: checkedItems.contains(checkIdx) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(checkedItems.contains(checkIdx) ? AppColors.success : AppColors.tertiaryText)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundStyle(checkedItems.contains(checkIdx) ? AppColors.tertiaryText : AppColors.secondText)
                                .strikethrough(checkedItems.contains(checkIdx))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }
                    .buttonStyle(.plain)
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

                ForEach(Array(lesson.strategy.commonMistakes.content.enumerated()), id: \.element.problem) { index, mistake in
                    let checkIdx = lessonCheckIndex(section: 1, item: index)
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            if checkedItems.contains(checkIdx) {
                                checkedItems.remove(checkIdx)
                            } else {
                                checkedItems.insert(checkIdx)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: checkedItems.contains(checkIdx) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(checkedItems.contains(checkIdx) ? AppColors.success : AppColors.tertiaryText)
                                Text(mistake.problem)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.primaryText)
                            }

                            (
                                Text("Why it hurts  ")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "EF4444").opacity(0.82))
                                + Text(mistake.whyItHurts)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.tertiaryText)
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 26)

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
                            .padding(.leading, 26)

                            if mistake.problem != lesson.strategy.commonMistakes.content.last?.problem {
                                Divider().background(AppColors.border.opacity(0.5))
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
                    let checkIdx = lessonCheckIndex(section: 2, item: index)
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            if checkedItems.contains(checkIdx) {
                                checkedItems.remove(checkIdx)
                            } else {
                                checkedItems.insert(checkIdx)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: checkedItems.contains(checkIdx) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(checkedItems.contains(checkIdx) ? AppColors.success : AppColors.tertiaryText)
                                Text(mistake.problem)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                            }

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
                            .padding(.leading, 26)

                            HStack(alignment: .top, spacing: 8) {
                                Text("Better")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.success)
                                Text(mistake.betterExample)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Button {
                                    WordPronouncer.shared.speak(mistake.betterExample, locale: "en-US", rate: 0.46, sourceLabel: "Review")
                                    listenedExamples.insert(index)
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppColors.success)
                                        .frame(width: 26, height: 26)
                                        .background(AppColors.success.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading, 26)

                            Text(mistake.reason)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 26)

                            if mistake.problem != lesson.strategy.commonMistakes.language.last?.problem {
                                Divider().background(AppColors.border.opacity(0.5))
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .cardStyle()
            .staggerIn(index: 3, appeared: appeared)
        }
    }
}
