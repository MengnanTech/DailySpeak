import SwiftUI

struct ReviewStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var appeared = false
    private var lesson: LessonContent? { task.lessonContent }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "高分检查",
                    subtitle: "骨架搭好后，再查内容力度和语言自然度。",
                    accentColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "checklist",
                    title: "高分检查",
                    english: "Score Check",
                    subtitle: "答完前快速检查内容完整度和语言准确度",
                    accentColor: Color(hex: "F97316"),
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

    private var standardReviewContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("开口前，最后检查")
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)

            ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .frame(width: 18, height: 18)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Circle())

                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .cardStyle()
        .staggerIn(index: 1, appeared: appeared)
    }

    private func lessonReviewContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("高分提醒")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(lesson.strategy.highScoreTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(accentColor)
                            .padding(.top, 3)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 1, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                Text("内容避坑")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(lesson.strategy.commonMistakes.content, id: \.problem) { mistake in
                    lessonMistakeRow(
                        title: mistake.problem,
                        detail: mistake.whyItHurts,
                        fix: mistake.fix,
                        tint: Color(hex: "EF4444")
                    )
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                Text("语言修正")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(lesson.strategy.commonMistakes.language, id: \.problem) { mistake in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mistake.problem)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

                        lessonComparisonLine(
                            tag: "Wrong",
                            text: mistake.wrongExample,
                            tagTint: Color(hex: "B91C1C"),
                            textColor: AppColors.primaryText
                        )

                        lessonComparisonLine(
                            tag: "Better",
                            text: mistake.betterExample,
                            tagTint: AppColors.success,
                            textColor: AppColors.primaryText
                        )

                        Text(mistake.reason)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 3, appeared: appeared)
        }
    }

    private func lessonMistakeRow(title: String, detail: String, fix: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.85), tint.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                (
                    Text("Why it hurts")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(tint.opacity(0.82))
                    + Text("  ")
                    + Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                )
                .fixedSize(horizontal: false, vertical: true)

                (
                    Text("Try this")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText.opacity(0.72))
                    + Text("  ")
                    + Text(fix)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                )
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.background.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border.opacity(0.65), lineWidth: 0.8)
                )
            }
            .padding(.vertical, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 0.8)
        )
    }

    private func lessonComparisonLine(tag: String, text: String, tagTint: Color, textColor: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(tag)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(tagTint)
                .clipShape(Capsule())

            Text(text)
                .font(.caption)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
