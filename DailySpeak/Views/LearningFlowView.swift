import SwiftUI
import AVFoundation

struct LearningFlowView: View {
    @Environment(ProgressManager.self) private var progress
    @Environment(\.dismiss) private var dismiss
    let stage: Stage
    let task: SpeakingTask

    @State private var currentStep: Int

    private var theme: StageTheme { stage.theme }
    private var steps: [LearningStep] { task.steps }

    init(stage: Stage, task: SpeakingTask) {
        self.stage = stage
        self.task = task
        _currentStep = State(initialValue: 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
            stepContent
            bottomBar
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(steps[currentStep].title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .onAppear { syncCurrentStep() }
    }

    private func syncCurrentStep() {
        let saved = progress.currentStepIndex(
            stageId: stage.id,
            taskId: task.id,
            totalSteps: steps.count
        )
        currentStep = min(saved, steps.count - 1)
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index < currentStep
                            ? AppColors.success
                            : index == currentStep
                                ? theme.startColor
                                : AppColors.border
                    )
                    .frame(height: 4)
                    .onTapGesture { withAnimation(.spring(duration: 0.35)) { currentStep = index } }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.card)
    }

    // MARK: - Step Content
    private var stepContent: some View {
        TabView(selection: $currentStep) {
            ForEach(0..<steps.count, id: \.self) { index in
                ScrollView(showsIndicators: false) {
                    stepView(for: steps[index].type)
                        .padding(.horizontal, 20)
                        .padding(.top, 0)
                        .padding(.bottom, 100)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(duration: 0.35), value: currentStep)
    }

    @ViewBuilder
    private func stepView(for type: StepType) -> some View {
        switch type {
        case .strategy:   StrategyStepView(task: task, accentColor: theme.startColor)
        case .review:     ReviewStepView(task: task, accentColor: theme.startColor)
        case .vocabulary:  VocabularyStepView(task: task, accentColor: theme.startColor)
        case .phrases:     PhrasesStepView(task: task, accentColor: theme.startColor)
        case .framework:   FrameworkStepView(task: task, accentColor: theme.startColor)
        case .samples:     SamplesStepView(task: task, accentColor: theme.startColor)
        case .practice:    PracticePromptView(stageId: stage.id, task: task, accentColor: theme.startColor)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(duration: 0.35)) { currentStep -= 1 }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.caption.bold())
                        Text("Back")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(AppColors.secondText)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Button {
                markCurrentComplete()
                if currentStep < steps.count - 1 {
                    withAnimation(.spring(duration: 0.35)) { currentStep += 1 }
                } else {
                    finishTask()
                }
            } label: {
                HStack(spacing: 5) {
                    Text(currentStep < steps.count - 1 ? "Next" : "Complete")
                        .font(.subheadline.bold())
                    Image(systemName: currentStep < steps.count - 1 ? "chevron.right" : "checkmark")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            AppColors.card
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func markCurrentComplete() {
        progress.completeStep(stageId: stage.id, taskId: task.id, stepIndex: currentStep)
    }

    private func finishTask() {
        progress.completeTask(stageId: stage.id, taskId: task.id)
        dismiss()
    }
}

// MARK: - Step Hero Header
struct StepHeroHeader: View {
    let icon: String
    let title: String
    let english: String
    let subtitle: String
    let accentColor: Color
    var secondaryColor: Color? = nil

    private var endColor: Color { secondaryColor ?? accentColor.opacity(0.7) }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [accentColor, endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Decorative
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 80)
                    .offset(x: geo.size.width - 50, y: -25)
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 55)
                    .offset(x: geo.size.width - 20, y: 40)
            }

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(english.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(1.2)

                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(18)
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct LessonStepHeader: View {
    let label: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .tracking(1.1)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppColors.primaryText)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - Staggered Animation Modifier
struct StaggeredAppear: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.78).delay(0.06 * Double(index) + 0.1),
                value: appeared
            )
    }
}

extension View {
    func staggerIn(index: Int, appeared: Bool) -> some View {
        modifier(StaggeredAppear(index: index, appeared: appeared))
    }
}

// MARK: - Strategy Step
struct StrategyStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var appeared = false
    private var lesson: LessonContent? { task.lessonContent }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "先搭答案骨架",
                    subtitle: "先定人物关系和特质，再用一个故事收住影响。",
                    accentColor: Color(hex: "F59E0B")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "lightbulb.max.fill",
                    title: "答题策略",
                    english: "Strategy & Tips",
                    subtitle: "了解如何组织你的回答，掌握答题思路",
                    accentColor: Color(hex: "F59E0B"),
                    secondaryColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            if let lesson {
                lessonStrategyContent(lesson)
            } else {
                standardStrategyContent
            }
        }
        .onAppear { appeared = true }
    }

    private var standardStrategyContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(task.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(accentColor)
                            .clipShape(Circle())

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 1, appeared: appeared)

            VStack(alignment: .leading, spacing: 8) {
                Text("TOPIC")
                    .font(.caption2.bold())
                    .foregroundStyle(accentColor)
                    .tracking(1)
                Text(task.prompt)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText)
                    .italic()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "EF4444"))
                        .clipShape(Circle())
                    Text("过关标准")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)
                }

                ForEach(task.passCriteria, id: \.self) { criteria in
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.system(size: 8))
                            .foregroundStyle(accentColor)
                        Text(criteria)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
                    }
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 3, appeared: appeared)
        }
    }

    private func lessonStrategyContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("先想这 4 点")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(Array(lesson.strategy.angles.enumerated()), id: \.offset) { index, angle in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(angle.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(angle.content, id: \.self) { item in
                            Text(item)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 32)
                        }
                    }
                }
            }
            .staggerIn(index: 2, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                Text("按这个顺序说")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(Array(lesson.strategy.sequence.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .frame(width: 18, height: 18)
                                .background(accentColor.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(item.phase)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppColors.primaryText)

                                    Text(item.focus)
                                        .font(.caption)
                                        .foregroundStyle(accentColor)
                                }

                                Text(item.target)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.tertiaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if index < lesson.strategy.sequence.count - 1 {
                            Divider().background(AppColors.border.opacity(0.7))
                                .padding(.leading, 28)
                        }
                    }
                }

                Divider().background(AppColors.border)

                Text("内容分配")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(lesson.strategy.contentRatio, id: \.label) { ratio in
                    HStack {
                        Text(ratio.label)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondText)
                        Spacer()
                        Text(ratio.value)
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 3, appeared: appeared)
        }
    }
}

// MARK: - Vocabulary Step
private enum VocabCategory: String, CaseIterable {
    case core
    case extended

    var title: String {
        switch self {
        case .core: "核心词汇"
        case .extended: "扩展词汇"
        }
    }
}

private enum VocabViewMode: String, CaseIterable {
    case list
    case flashcard

    var icon: String {
        switch self {
        case .list: "list.bullet"
        case .flashcard: "rectangle.on.rectangle.angled"
        }
    }

    var label: String {
        switch self {
        case .list: "列表"
        case .flashcard: "闪卡"
        }
    }
}

struct VocabularyStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var selectedCategory: VocabCategory = .core
    @State private var selectedItem: VocabItem?
    @State private var showUpgrade = true
    @State private var showAdvanced = false
    @State private var viewMode: VocabViewMode = .list
    @State private var flashcardIndex = 0
    @State private var flashcardFlipped = false
    @State private var appeared = false
    private var hasLessonContent: Bool { task.lessonContent != nil }

    private var coreItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .core }
    }

    private var upgradeItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .upgrade }
    }

    private var advancedItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .advanced }
    }

    private var currentFlashcardItems: [VocabItem] {
        selectedCategory == .core ? coreItems : (upgradeItems + advancedItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "核心词汇",
                    subtitle: "先抓最常用的描述词，再补更成熟的升级表达。",
                    accentColor: Color(hex: "4A90D9")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "character.book.closed.fill",
                    title: "核心词汇",
                    english: "Key Vocabulary",
                    subtitle: "掌握 \(coreItems.count) 个核心词 · \(upgradeItems.count + advancedItems.count) 个进阶词",
                    accentColor: Color(hex: "4A90D9"),
                    secondaryColor: Color(hex: "7AB4E8")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Mode switcher: List / Flashcard
            HStack(spacing: 0) {
                ForEach(VocabViewMode.allCases, id: \.self) { mode in
                    let isSelected = viewMode == mode
                    Button {
                        withAnimation(.spring(duration: 0.28)) { viewMode = mode; flashcardIndex = 0; flashcardFlipped = false }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(mode.label)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(isSelected ? .white : AppColors.secondText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(isSelected ? accentColor : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .staggerIn(index: 1, appeared: appeared)

            // Category switcher
            categorySwitcher
                .staggerIn(index: 2, appeared: appeared)

            if viewMode == .flashcard {
                flashcardView
                    .staggerIn(index: 3, appeared: appeared)
            } else {
                if selectedCategory == .core {
                    vocabList(items: coreItems)
                        .staggerIn(index: 3, appeared: appeared)
                } else {
                    extendedSectionCard
                        .staggerIn(index: 3, appeared: appeared)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            VocabDetailSheet(item: item, accentColor: accentColor)
                .presentationBackground(AppColors.background)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Flashcard View
    private var flashcardView: some View {
        let items = currentFlashcardItems
        guard !items.isEmpty else {
            return AnyView(
                Text("No vocabulary items")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            )
        }
        let item = items[flashcardIndex % items.count]

        return AnyView(
            VStack(spacing: 16) {
                // Card
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        flashcardFlipped.toggle()
                    }
                } label: {
                    ZStack {
                        if !flashcardFlipped {
                            // Front: word + phonetic
                            VStack(spacing: 12) {
                                Text(item.word)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryText)

                                if !item.phonetic.isEmpty {
                                    Text(item.phonetic)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                Text(item.partOfSpeech)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(item.band.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(item.band.color.opacity(0.12))
                                    .clipShape(Capsule())

                                Spacer().frame(height: 8)

                                Text("tap to flip")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                            .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                        } else {
                            // Back: meaning + example
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.word)
                                        .font(.headline)
                                        .foregroundStyle(AppColors.primaryText)
                                    Spacer()
                                    Button {
                                        WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(item.band.color)
                                            .frame(width: 32, height: 32)
                                            .background(item.band.color.opacity(0.12))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(item.meaning)
                                    .font(.title3.bold())
                                    .foregroundStyle(accentColor)

                                if !item.englishMeaning.isEmpty {
                                    Text(item.englishMeaning)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondText)
                                }

                                if let sourceBand = item.sourceBand ?? item.nativeNote {
                                    Text(sourceBand)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                Divider().background(AppColors.border)

                                if !item.example.isEmpty {
                                    Text(item.example)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.primaryText)
                                        .italic()
                                }

                                if !item.exampleTranslation.isEmpty {
                                    Text(item.exampleTranslation)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .rotation3DEffect(.degrees(0), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 220)
                    .padding(24)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                flashcardFlipped ? item.band.color.opacity(0.2) : AppColors.border.opacity(0.5),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: accentColor.opacity(0.1), radius: 16, x: 0, y: 8)
                    .rotation3DEffect(
                        .degrees(flashcardFlipped ? 0 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                }
                .buttonStyle(.plain)

                // Navigation
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            flashcardFlipped = false
                            flashcardIndex = (flashcardIndex - 1 + items.count) % items.count
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.secondText)
                            .frame(width: 44, height: 44)
                            .background(AppColors.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Text("\(flashcardIndex % items.count + 1) / \(items.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.secondText)
                        .frame(minWidth: 50)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            flashcardFlipped = false
                            flashcardIndex = (flashcardIndex + 1) % items.count
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        )
    }

    private var categorySwitcher: some View {
        HStack(spacing: 10) {
            ForEach(VocabCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                let count = category == .core ? coreItems.count : (upgradeItems.count + advancedItems.count)

                Button {
                    withAnimation(.spring(duration: 0.28)) {
                        selectedCategory = category
                        flashcardIndex = 0
                        flashcardFlipped = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(category.title)
                            .font(.subheadline.bold())
                        Text("\(count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.white.opacity(isSelected ? 0.22 : 0.08))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(isSelected ? .white : AppColors.secondText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background {
                        if isSelected {
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            AppColors.card
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border.opacity(isSelected ? 0.0 : 0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var extendedSectionCard: some View {
        VStack(spacing: 10) {
            DisclosureGroup(isExpanded: $showUpgrade) {
                VStack(spacing: 10) {
                    vocabList(items: upgradeItems)
                }
                .padding(.top, 10)
            } label: {
                sectionTag(title: "进阶词汇", count: upgradeItems.count, color: Color(hex: "F59E0B"), caption: "日常表达升级")
            }

            Divider().background(AppColors.border.opacity(0.35))

            DisclosureGroup(isExpanded: $showAdvanced) {
                VStack(spacing: 10) {
                    vocabList(items: advancedItems)
                }
                .padding(.top, 10)
            } label: {
                sectionTag(title: "高分词汇", count: advancedItems.count, color: Color(hex: "EF4444"), caption: "高阶表达与观点深度")
            }
        }
    }

    private func sectionTag(title: String, count: Int, color: Color, caption: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
            Spacer()
            Text(caption)
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
        }
    }

    private func vocabList(items: [VocabItem]) -> some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                VocabCardView(
                    item: item,
                    onShowMeaning: { selectedItem = item },
                    onPronounce: { WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48) }
                )
            }
        }
    }
}

struct VocabCardView: View {
    let item: VocabItem
    let onShowMeaning: () -> Void
    let onPronounce: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.word)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    HStack(spacing: 8) {
                        if !item.phonetic.isEmpty {
                            Text(item.phonetic)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.secondText)
                        }

                        Text(item.partOfSpeech)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(item.band.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.band.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    onPronounce()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(item.band.color)
                        .frame(width: 34, height: 34)
                        .background(item.band.color.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button {
                    onShowMeaning()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("释义")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(item.band.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.band.color.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.band.bandLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.tertiaryText)
                    if let sourceBand = item.sourceBand {
                        Text(sourceBand)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(item.band.color)
                    }
                }
            }
        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.band.color.opacity(0.16), lineWidth: 1)
        )
        .cardShadow()
    }
}

struct VocabDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: VocabItem
    let accentColor: Color

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(item.word)
                                .font(.title2.bold())
                                .foregroundStyle(AppColors.primaryText)
                            if !item.phonetic.isEmpty {
                                Text(item.phonetic)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                            Text(item.partOfSpeech)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Text(item.meaning)
                            .font(.headline)
                            .foregroundStyle(accentColor)

                        if !item.englishMeaning.isEmpty {
                            Text(item.englishMeaning)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                        }

                        if let sourceBand = item.sourceBand {
                            Text(sourceBand)
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.tertiaryText)
                        }

                        if let nativeNote = item.nativeNote {
                            Text(nativeNote)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("发音")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

                        HStack(spacing: 10) {
                            pronunciationButton(title: "US", icon: "waveform") {
                                WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.48)
                            }
                            pronunciationButton(title: "UK", icon: "waveform.path.ecg") {
                                WordPronouncer.shared.speak(item.word, locale: "en-GB", rate: 0.48)
                            }
                            pronunciationButton(title: "Slow", icon: "tortoise.fill") {
                                WordPronouncer.shared.speak(item.word, locale: "en-US", rate: 0.34)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()

                    if !item.example.isEmpty || !item.exampleTranslation.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("例句")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                            if !item.example.isEmpty {
                                Text(item.example)
                                    .font(.body)
                                    .foregroundStyle(AppColors.primaryText)
                            }
                            if !item.exampleTranslation.isEmpty {
                                Text(item.exampleTranslation)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.tertiaryText)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .cardShadow()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
    }

    private func pronunciationButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

final class WordPronouncer {
    static let shared = WordPronouncer()

    private init() {}

    func speak(_ text: String, locale: String, rate: Float) {
        guard !text.isEmpty else { return }
        guard locale.lowercased().hasPrefix("en") else { return }
        EnglishSpeechPlayer.shared.togglePlayback(
            id: playbackID(for: text, locale: locale, rate: rate),
            text: text
        )
    }

    func playbackID(for text: String, locale _: String, rate _: Float) -> String {
        EnglishSpeechPlayer.playbackID(for: text)
    }
}

// MARK: - Phrases Step
struct PhrasesStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var appeared = false
    private var hasLessonContent: Bool { task.lessonContent != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "实用词组",
                    subtitle: "用短语拉开自然度，避免一句一句直译。",
                    accentColor: Color(hex: "10B981")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "quote.bubble.fill",
                    title: "实用词组",
                    english: "Useful Phrases",
                    subtitle: "掌握 \(task.phrases.count) 个地道表达，让口语更自然",
                    accentColor: Color(hex: "10B981"),
                    secondaryColor: Color(hex: "34D399")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            ForEach(Array(task.phrases.enumerated()), id: \.element.id) { index, phrase in
                PhraseCard(phrase: phrase, index: index + 1, accentColor: accentColor)
                    .staggerIn(index: index + 1, appeared: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

struct PhraseCard: View {
    let phrase: PhraseItem
    let index: Int
    let accentColor: Color

    @State private var exampleVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: number + phrase + speak button
            HStack(alignment: .top, spacing: 12) {
                // Left color bar + number
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Text("\(index)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.phrase)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    if let meaning = phrase.meaning {
                        Text(meaning)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondText)
                    }
                }

                Spacer()

                Button {
                    WordPronouncer.shared.speak(phrase.phrase, locale: "en-US", rate: 0.46)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 10)

            // Example: tap to reveal
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    exampleVisible.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: exampleVisible ? "eye.fill" : "eye.slash")
                            .font(.system(size: 10, weight: .bold))
                        Text(exampleVisible ? "Example" : "Tap to see example")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(accentColor.opacity(0.7))

                    if let sourceBand = phrase.sourceBand {
                        Text(sourceBand)
                            .font(.caption2.bold())
                            .foregroundStyle(accentColor)
                    }

                    if exampleVisible {
                        if !phrase.example.isEmpty {
                            Text(phrase.example)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondText)
                                .italic()
                                .lineSpacing(3)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if let nativeNote = phrase.nativeNote {
                            Text(nativeNote)
                                .font(.caption)
                                .foregroundStyle(AppColors.tertiaryText)
                                .lineSpacing(2)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(accentColor.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(accentColor.opacity(0.5))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .cardShadow()
    }
}

// MARK: - Framework Step
struct FrameworkStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var appeared = false
    private let labels = ["开场", "来源", "使用", "例子", "收尾"]
    private var lesson: LessonContent? { task.lessonContent }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "表达框架",
                    subtitle: "先看总结构，再补连接表达和升级表达。",
                    accentColor: Color(hex: "8B5CF6")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "rectangle.3.group.fill",
                    title: "表达框架",
                    english: "Expression Framework",
                    subtitle: "掌握答题模板，让表达有条理",
                    accentColor: Color(hex: "8B5CF6"),
                    secondaryColor: Color(hex: "A78BFA")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            if let lesson {
                lessonFrameworkContent(lesson)
            } else {
                standardFrameworkContent
            }
        }
        .onAppear { appeared = true }
    }

    private var standardFrameworkContent: some View {
        Group {
            VStack(spacing: 10) {
                ForEach(Array(task.frameworkSentences.enumerated()), id: \.offset) { index, sentence in
                    FrameworkSentenceCard(
                        index: index + 1,
                        label: index < labels.count ? labels[index] : "要点",
                        sentence: sentence,
                        accentColor: accentColor,
                        isLast: index == task.frameworkSentences.count - 1
                    )
                    .staggerIn(index: index + 1, appeared: appeared)
                }
            }

            if !task.upgradeExpressions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Color(hex: "F59E0B"))
                            .clipShape(Circle())
                        Text("升级表达")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }

                    ForEach(Array(task.upgradeExpressions.enumerated()), id: \.offset) { idx, pair in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text("Before")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.tertiaryText)
                                    .clipShape(Capsule())
                                Text(pair.original)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.tertiaryText)
                                    .strikethrough()
                            }

                            HStack(spacing: 6) {
                                Text("After")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppColors.success)
                                    .clipShape(Capsule())
                                Text(pair.upgraded)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.primaryText)
                                    .bold()
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .cardShadow()
                        .staggerIn(index: task.frameworkSentences.count + idx + 1, appeared: appeared)
                    }
                }
                .staggerIn(index: task.frameworkSentences.count + 1, appeared: appeared)
            }
        }
    }

    private func lessonFrameworkContent(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Framework Goal")
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
                Text(lesson.framework.goal)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().background(AppColors.border)

                ForEach(lesson.framework.defaultStructure, id: \.section) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.section)
                            .font(.caption.bold())
                            .foregroundStyle(accentColor)

                        ForEach(section.moves, id: \.self) { move in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(accentColor)
                                    .padding(.top, 4)
                                Text(move)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.secondText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 1, appeared: appeared)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hex: "5B6EF5").opacity(0.12))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "text.quote")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "5B6EF5"))
                        )

                    Text("Delivery Markers")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)
                }

                Divider().background(AppColors.border)

                lessonMarkersContent(lesson.framework.deliveryMarkers)
            }
            .padding(16)
            .cardStyle()
            .staggerIn(index: 2, appeared: appeared)
        }
    }

    private func frameworkSection(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(accentColor)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func labelLine(tag: String, text: String, tint: Color, strike: Bool) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tint)
                .clipShape(Capsule())
            Text(text)
                .font(.caption)
                .foregroundStyle(strike ? AppColors.tertiaryText : AppColors.primaryText)
                .strikethrough(strike)
        }
    }

    private func lessonMarkersContent(_ markers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(markers, id: \.self) { marker in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "5B6EF5"))
                        .padding(.top, 3)
                    Text(marker)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct FrameworkSentenceCard: View {
    let index: Int
    let label: String
    let sentence: String
    let accentColor: Color
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: number + connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 28, height: 28)
                    Text("\(index)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            // Right: label + sentence with fill-in highlights
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)

                highlightedSentence(sentence)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
            .padding(.bottom, isLast ? 0 : 10)
        }
    }

    // Highlight `...` parts as fill-in blanks
    @ViewBuilder
    private func highlightedSentence(_ text: String) -> some View {
        let parts = text.components(separatedBy: "...")
        if parts.count > 1 {
            // Has fill-in blanks
            Text(buildAttributedSentence(text))
        } else {
            Text(text)
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private func buildAttributedSentence(_ text: String) -> AttributedString {
        var result = AttributedString()
        let segments = text.components(separatedBy: "...")

        for (i, segment) in segments.enumerated() {
            var part = AttributedString(segment)
            part.foregroundColor = AppColors.primaryText
            result.append(part)

            if i < segments.count - 1 {
                var blank = AttributedString("  ___  ")
                blank.foregroundColor = accentColor
                blank.font = .system(size: 15, weight: .bold, design: .rounded)
                result.append(blank)
            }
        }
        return result
    }
}

// MARK: - Samples Step
struct SamplesStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var selectedBand = 0
    @State private var appeared = false
    private var hasLessonContent: Bool { task.lessonContent != nil }
    private var lesson: LessonContent? { task.lessonContent }

    private var bandColors: [Color] {
        [Color(hex: "4A90D9"), Color(hex: "F59E0B"), Color(hex: "EF4444")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasLessonContent {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "范文学习",
                    subtitle: "用 Band 6 / 7 / 8 对照看内容深度和表达差异。",
                    accentColor: Color(hex: "EC4899")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "doc.richtext.fill",
                    title: "范文学习",
                    english: "Sample Answers",
                    subtitle: "三个水平的示范回答，对比学习",
                    accentColor: Color(hex: "EC4899"),
                    secondaryColor: Color(hex: "F472B6")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            // Band selector
            HStack(spacing: 8) {
                ForEach(Array(task.sampleAnswers.enumerated()), id: \.offset) { index, sample in
                    Button {
                        withAnimation(.spring(duration: 0.3)) { selectedBand = index }
                    } label: {
                        Text(sample.band)
                            .font(.caption.bold())
                            .foregroundStyle(selectedBand == index ? .white : bandColors[index])
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedBand == index
                                    ? bandColors[index]
                                    : bandColors[index].opacity(0.1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .staggerIn(index: 1, appeared: appeared)

            if selectedBand < task.sampleAnswers.count, let bandGuide = task.sampleAnswers[selectedBand].bandGuide {

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Band \(bandGuide.band) 表达框架")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Text(bandGuide.focus)
                            .font(.caption.bold())
                            .foregroundStyle(bandColors[selectedBand])
                    }

                    frameworkGuideSection(
                        title: "Opening",
                        lines: bandGuide.opening,
                        tint: bandColors[selectedBand]
                    )
                    frameworkGuideSection(
                        title: "Body",
                        lines: bandGuide.body,
                        tint: bandColors[selectedBand]
                    )
                    frameworkGuideSection(
                        title: "Closing",
                        lines: bandGuide.closing,
                        tint: bandColors[selectedBand]
                    )
                }
                .padding(16)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(bandColors[selectedBand].opacity(0.14), lineWidth: 1)
                )
                .cardShadow()
                .staggerIn(index: 2, appeared: appeared)
            }

            // Sample content
            if selectedBand < task.sampleAnswers.count {
                let sample = task.sampleAnswers[selectedBand]

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(sample.band)
                            .font(.caption.bold())
                            .foregroundStyle(bandColors[selectedBand])
                        Spacer()
                        Text("\(sample.wordCount) words")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }

                    Divider().background(AppColors.border)

                    // Highlighted sample content
                    highlightedSampleText(sample.content)
                        .lineSpacing(6)

                    // Audio button
                    Button {
                        WordPronouncer.shared.speak(sample.content, locale: "en-US", rate: 0.46)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            Text("Listen to Pronunciation")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(bandColors[selectedBand])
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(bandColors[selectedBand].opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if !sample.nativeFeatures.isEmpty {
                        Divider().background(AppColors.border)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Native Features")
                                .font(.caption.bold())
                                .foregroundStyle(bandColors[selectedBand])

                            ForEach(sample.nativeFeatures, id: \.self) { feature in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                        .foregroundStyle(bandColors[selectedBand])
                                        .padding(.top, 4)
                                    Text(feature)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondText)
                                }
                            }
                        }
                    }

                    if !sample.upgrades.isEmpty {
                        Divider().background(AppColors.border)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Expression Upgrades")
                                .font(.caption.bold())
                                .foregroundStyle(bandColors[selectedBand])

                            ForEach(Array(sample.upgrades.enumerated()), id: \.offset) { _, item in
                                VStack(alignment: .leading, spacing: 8) {
                                    upgradeLabelLine(tag: "Original", text: item.original, tint: AppColors.tertiaryText)
                                    upgradeLabelLine(tag: "Improved", text: item.improved, tint: bandColors[selectedBand])
                                    Text(item.why)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.secondText)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(item.note)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
                .padding(16)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(bandColors[selectedBand].opacity(0.15), lineWidth: 1)
                )
                .cardShadow()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .staggerIn(index: lesson == nil ? 2 : 3, appeared: appeared)
            }
        }
        .onAppear { appeared = true }
    }

    private func frameworkGuideSection(title: String, lines: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(tint)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(tint.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Highlight vocabulary words from this task in the sample text
    @ViewBuilder
    private func highlightedSampleText(_ content: String) -> some View {
        let vocabWords = Set(task.vocabulary.map { $0.word.lowercased() })
        let words = content.components(separatedBy: " ")

        Text(words.reduce(AttributedString()) { result, word in
            var r = result
            if !r.characters.isEmpty {
                r.append(AttributedString(" "))
            }
            let cleaned = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if vocabWords.contains(cleaned) {
                var attr = AttributedString(word)
                attr.foregroundColor = accentColor
                attr.font = .subheadline.bold()
                attr.underlineStyle = .single
                r.append(attr)
            } else {
                var attr = AttributedString(word)
                attr.foregroundColor = AppColors.primaryText
                attr.font = .subheadline
                r.append(attr)
            }
            return r
        })
    }

    private func upgradeLabelLine(tag: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tint)
                .clipShape(Capsule())
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Practice Prompt
private enum PracticeInputMode: String, CaseIterable, Identifiable {
    case text = "文字输入"
    case voice = "语音输入"

    var id: String { rawValue }
}

private enum PracticeLanguageMode: String, CaseIterable, Identifiable {
    case native = "母语输入"
    case english = "英文草稿"

    var id: String { rawValue }
}

struct PracticePromptView: View {
    let stageId: Int
    let task: SpeakingTask
    let accentColor: Color
    private let labels = ["开场", "来源", "使用", "例子", "收尾"]
    private var lesson: LessonContent? { task.lessonContent }

    @StateObject private var speechInput = SpeechInputManager()
    @State private var inputMode: PracticeInputMode = .text
    @State private var languageMode: PracticeLanguageMode = .native
    @State private var draftInput: String
    @State private var translatedEnglish: String
    @State private var polishedEnglish: String
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @FocusState private var isInputFocused: Bool

    init(stageId: Int, task: SpeakingTask, accentColor: Color) {
        self.stageId = stageId
        self.task = task
        self.accentColor = accentColor

        let defaults = UserDefaults.standard
        let base = "practice_s\(stageId)_t\(task.id)"
        _draftInput = State(initialValue: defaults.string(forKey: "\(base)_draft") ?? "")
        _translatedEnglish = State(initialValue: defaults.string(forKey: "\(base)_translated") ?? "")
        _polishedEnglish = State(initialValue: defaults.string(forKey: "\(base)_polished") ?? "")
    }

    private var baseKey: String {
        "practice_s\(stageId)_t\(task.id)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if lesson != nil {
                LessonStepHeader(
                    label: task.lessonContent?.topic.stageLabel ?? "Structured Lesson",
                    title: "口语练习",
                    subtitle: "按提示把内容真正说出来，不要只停留在阅读。",
                    accentColor: Color(hex: "EF4444")
                )
                .staggerIn(index: 0, appeared: appeared)
            } else {
                StepHeroHeader(
                    icon: "mic.fill",
                    title: "口语练习",
                    english: "Speaking Practice",
                    subtitle: "实战演练，开口说英语",
                    accentColor: Color(hex: "EF4444"),
                    secondaryColor: Color(hex: "F97316")
                )
                .staggerIn(index: 0, appeared: appeared)
            }

            topicCard
                .staggerIn(index: 1, appeared: appeared)
            if let lesson {
                practiceChecklistCard(lesson)
                    .staggerIn(index: 2, appeared: appeared)
            }
            frameworkHints
                .staggerIn(index: 3, appeared: appeared)
            inputCard
                .staggerIn(index: 4, appeared: appeared)
            actionArea
                .staggerIn(index: 5, appeared: appeared)

            if !translatedEnglish.isEmpty {
                resultCard(
                    title: languageMode == .native ? "英文结果（API）" : "当前英文草稿",
                    subtitle: languageMode == .native ? "基于当前后端 contract 的翻译结果" : "当前后端没有额外润色接口，保留你的英文输入",
                    text: translatedEnglish,
                    tint: Color(hex: "4A90D9")
                )
            }

            if !polishedEnglish.isEmpty {
                resultCard(
                    title: "保留字段",
                    subtitle: "等待后端补充 DailySpeak 专用润色接口后再恢复",
                    text: polishedEnglish,
                    tint: Color(hex: "10B981")
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "DC2626"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "FEE2E2"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .onChange(of: draftInput) { _, newValue in
            save(newValue, key: "\(baseKey)_draft")
        }
        .onChange(of: translatedEnglish) { _, newValue in
            save(newValue, key: "\(baseKey)_translated")
        }
        .onChange(of: polishedEnglish) { _, newValue in
            save(newValue, key: "\(baseKey)_polished")
        }
        .onChange(of: speechInput.transcript) { _, transcript in
            guard !transcript.isEmpty else { return }
            draftInput = transcript
            save(transcript, key: "\(baseKey)_voice")
        }
        .onDisappear {
            speechInput.stopRecording()
        }
        .onAppear { appeared = true }
    }

    private var topicCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TOPIC")
                    .font(.caption2.bold())
                    .foregroundStyle(accentColor)
                    .tracking(1)
                Spacer()
                if let lesson {
                    Text(lesson.practice.targetLength)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            if let lesson {
                Text(lesson.practice.task)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            Text(task.prompt)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
    }

    private func practiceChecklistCard(_ lesson: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speaking Checklist")
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)

            ForEach(lesson.practice.checklist, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(accentColor)
                        .padding(.top, 3)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                }
            }

            Divider().background(AppColors.border)

            Text("Self Prompts")
                .font(.caption.bold())
                .foregroundStyle(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lesson.practice.selfPrompts, id: \.self) { prompt in
                        Text(prompt)
                            .font(.caption.bold())
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(accentColor.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var frameworkHints: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.caption)
                    .foregroundStyle(accentColor)
                Text("表达框架提示")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }

            ForEach(Array(task.frameworkSentences.enumerated()), id: \.offset) { index, sentence in
                HStack(alignment: .top, spacing: 8) {
                    Text(index < labels.count ? labels[index] : "要点")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    Text(sentence)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 0.8)
        )
        .cardShadow()
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("输入你的回答草稿")
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)

            modeSelector(
                title: "输入方式",
                items: PracticeInputMode.allCases,
                selected: inputMode
            ) { inputMode = $0 }

            if inputMode == .text {
                modeSelector(
                    title: "内容类型",
                    items: PracticeLanguageMode.allCases,
                    selected: languageMode
                ) { languageMode = $0 }
            }

            if inputMode == .voice {
                voiceTools
            }

            draftEditor

            if let speechError = speechInput.lastError {
                Text(speechError)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "DC2626"))
            }

            Text("草稿会自动保存。你可以先用母语输入，再通过当前后端接口转成英文。")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(16)
        .cardStyle()
    }

    private var voiceTools: some View {
        HStack(spacing: 10) {
            Button {
                Task { await speechInput.toggleRecording() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: speechInput.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(speechInput.isRecording ? "停止录音" : "开始录音")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(speechInput.isRecording ? Color(hex: "DC2626") : accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if speechInput.isRecording {
                Text("识别中...")
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var draftEditor: some View {
        TextEditor(text: $draftInput)
            .focused($isInputFocused)
            .frame(minHeight: 120)
            .padding(10)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isInputFocused ? accentColor : AppColors.border, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if draftInput.isEmpty {
                    Text(languageMode == .native ? "先输入母语内容，建议 4-6 句..." : "先写英文草稿，当前会保留你的原文...")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
    }

    private var actionArea: some View {
        Button {
            runPipeline()
        } label: {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.subheadline.bold())
                }
                Text(languageMode == .native ? "母语 -> 英文" : "保留英文草稿")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing
                    ? AnyShapeStyle(AppColors.border)
                    : AnyShapeStyle(accentColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(draftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
    }

    private func resultCard(title: String, subtitle: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Button {
                    WordPronouncer.shared.speak(text, locale: "en-US", rate: 0.46)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption.bold())
                        Text("播放")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(5)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .cardShadow()
    }

    private func modeSelector<Item: Identifiable>(
        title: String,
        items: [Item],
        selected: Item,
        onSelect: @escaping (Item) -> Void
    ) -> some View where Item: RawRepresentable, Item.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppColors.tertiaryText)

            HStack(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = item.id == selected.id
                    Button {
                        withAnimation(.spring(duration: 0.24)) {
                            onSelect(item)
                        }
                    } label: {
                        Text(item.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(isSelected ? .white : AppColors.secondText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(isSelected ? accentColor : AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func runPipeline() {
        let source = draftInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return }
        isProcessing = true
        errorMessage = nil
        isInputFocused = false

        Task {
            do {
                let translated: String
                if languageMode == .native {
                    translated = try await PracticeAIService.shared.translateToEnglish(
                        nativeText: source,
                        topic: task.prompt
                    )
                } else {
                    translated = source
                }

                translatedEnglish = translated
                polishedEnglish = ""
                isProcessing = false
            } catch {
                isProcessing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save(_ value: String, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
