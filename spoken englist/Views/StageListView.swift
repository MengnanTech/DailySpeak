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
        VStack(alignment: .leading, spacing: 6) {
            Text("IELTS Speaking")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.primaryText)

            Text("Master your spoken English, one stage at a time")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 15)
    }

    // MARK: - Hero Card (Current Stage)
    private var heroCard: some View {
        let current = currentStage
        let theme = current.theme

        return Button { selectedStage = current } label: {
            ZStack(alignment: .leading) {
                theme.gradient
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.09))
                        .frame(width: 140)
                        .offset(x: geo.size.width - 70, y: -45)
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 100)
                        .offset(x: geo.size.width - 20, y: 75)
                    Circle()
                        .fill(.white.opacity(0.04))
                        .frame(width: 60)
                        .offset(x: -15, y: 100)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT STAGE")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .tracking(1.5)
                            Text("Stage \(current.id)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Text(theme.emoji)
                            .font(.system(size: 42))
                    }
                    .padding(.bottom, 14)

                    Text(current.chineseTitle)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .padding(.bottom, 2)

                    Text(current.title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 16)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(.white)
                                    .frame(width: max(0, geo.size.width * progress.stageProgress(for: current)), height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(progress.completedTaskCount(for: current))/\(current.taskCount) tasks")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Continue")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(theme.startColor)
                                Image(systemName: "arrow.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(theme.startColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(.white)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(22)
            }
            .frame(height: 210)
            .heroShadow(color: theme.start)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .opacity(appearAnimations ? 1 : 0)
        .offset(y: appearAnimations ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: appearAnimations)
    }

    // MARK: - Stage Grid
    private var stageGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                // Top: Emoji + Stage Number
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.gradient)
                            .frame(width: 42, height: 42)
                        Text(theme.emoji)
                            .font(.title3)
                    }
                    Spacer()
                    Text("S\(stage.id)")
                        .font(.caption2.bold())
                        .foregroundStyle(theme.startColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.startColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 12)

                // Title
                Text(stage.chineseTitle)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.bottom, 2)

                Text(stage.title)
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.bottom, 12)

                Spacer(minLength: 0)

                // Progress
                VStack(alignment: .leading, spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.surface)
                                .frame(height: 5)
                            Capsule()
                                .fill(theme.gradient)
                                .frame(width: max(0, geo.size.width * prog), height: 5)
                        }
                    }
                    .frame(height: 5)

                    HStack {
                        Text("\(completedCount)/\(stage.taskCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(theme.startColor)
                        Spacer()
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.success)
                        }
                    }
                }
            }
            .padding(16)
            .frame(height: 175)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isCompleted ? AppColors.success.opacity(0.3) : theme.startColor.opacity(0.08), lineWidth: 1)
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
