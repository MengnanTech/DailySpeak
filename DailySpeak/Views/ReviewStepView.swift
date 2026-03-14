import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var appeared = false
    private var lesson: LessonContent? { task.lessonContent }
    private let reviewColor = Color(hex: "F97316")

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
        .onAppear { appeared = true }
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
                HStack(alignment: .top, spacing: 12) {
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
                }
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

                ForEach(lesson.strategy.highScoreTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(reviewColor)
                            .padding(.top, 4)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
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

                ForEach(lesson.strategy.commonMistakes.content, id: \.problem) { mistake in
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

                ForEach(lesson.strategy.commonMistakes.language, id: \.problem) { mistake in
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

                        Text(mistake.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)

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
