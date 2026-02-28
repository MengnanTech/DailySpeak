import SwiftUI

struct StageListView: View {
    @Environment(ProgressManager.self) private var progress
    @State private var selectedStage: Stage?
    @State private var appearAnimations = false

    private let stages = CourseData.stages
    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    heroCard
                    stageGrid
                }
                .padding(.bottom, 40)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationDestination(item: $selectedStage) { stage in
                TaskGridView(stage: stage)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appearAnimations = true }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks")
                    .font(.title.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text("Master your English, one stage at a time")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 10)
    }

    // MARK: - Hero Card (Current Stage)
    private var heroCard: some View {
        let current = currentStage
        let theme = current.theme

        return Button { selectedStage = current } label: {
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.softGradient)

                // Decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100)
                        .offset(x: geo.size.width - 55, y: -25)
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 70)
                        .offset(x: geo.size.width - 10, y: 55)
                }

                // Content
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Stage \(current.id)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.75))
                            .tracking(1)

                        Text(current.chineseTitle)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(current.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)

                        // Progress
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.2)).frame(height: 5)
                                    Capsule().fill(.white)
                                        .frame(
                                            width: max(0, geo.size.width * progress.stageProgress(for: current)),
                                            height: 5
                                        )
                                }
                            }
                            .frame(height: 5)
                            .frame(maxWidth: 140)

                            Text("\(progress.completedTaskCount(for: current))/\(current.taskCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    Spacer(minLength: 12)

                    // Right side: emoji + arrow
                    VStack(spacing: 10) {
                        Text(theme.emoji)
                            .font(.system(size: 34))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .frame(height: 150)
            .heroShadow(color: theme.start)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 15)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: appearAnimations)
    }

    // MARK: - Stage Grid
    private var stageGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ALL STAGES")
                .font(.caption.bold())
                .foregroundStyle(AppColors.tertiaryText)
                .tracking(1.2)
                .padding(.horizontal, 20)

            LazyVGrid(columns: gridColumns, spacing: 14) {
                ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                    StageGridCard(stage: stage) {
                        selectedStage = stage
                    }
                    .opacity(appearAnimations ? 1 : 0)
                    .offset(y: appearAnimations ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.5).delay(0.15 + Double(index) * 0.05),
                        value: appearAnimations
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Current Stage Helper
    private var currentStage: Stage {
        stages.first { progress.stageProgress(for: $0) < 1.0 } ?? stages.last!
    }
}

// MARK: - Stage Grid Card
struct StageGridCard: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let onTap: () -> Void

    private var theme: StageTheme { stage.theme }
    private var completedCount: Int { progress.completedTaskCount(for: stage) }
    private var prog: Double { progress.stageProgress(for: stage) }
    private var isCompleted: Bool { prog >= 1.0 }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Top: Emoji badge + Stage number
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.gradient)
                            .frame(width: 40, height: 40)
                        Text(theme.emoji)
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Text("S\(stage.id)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.startColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(theme.startColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 10)

                Text(stage.chineseTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.bottom, 2)

                Text(stage.title)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.tertiaryText)

                Spacer(minLength: 0)

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(AppColors.surface).frame(height: 4)
                            Capsule().fill(theme.gradient)
                                .frame(width: max(0, geo.size.width * prog), height: 4)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text("\(completedCount)/\(stage.taskCount)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.startColor)
                        Spacer()
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.success)
                        }
                    }
                }
            }
            .padding(14)
            .frame(height: 158)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isCompleted ? AppColors.success.opacity(0.25) : AppColors.border.opacity(0.6),
                        lineWidth: 1
                    )
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stage Identifiable + Hashable
extension Stage: Hashable {
    static func == (lhs: Stage, rhs: Stage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
