import SwiftUI
import AVFoundation

struct LearningFlowView: View {
    @Environment(ProgressManager.self) private var progress
    let stage: Stage
    let task: SpeakingTask

    @State private var currentStep: Int
    @State private var showPractice = false

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
        .navigationDestination(isPresented: $showPractice) {
            PracticeView(stage: stage, task: task)
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
                        .padding(.top, 16)
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
        case .vocabulary:  VocabularyStepView(task: task, accentColor: theme.startColor)
        case .phrases:     PhrasesStepView(task: task, accentColor: theme.startColor)
        case .framework:   FrameworkStepView(task: task, accentColor: theme.startColor)
        case .samples:     SamplesStepView(task: task, accentColor: theme.startColor)
        case .practice:    PracticePromptView(task: task, accentColor: theme.startColor)
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
        showPractice = true
    }
}

// MARK: - Strategy Step
struct StrategyStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "lightbulb.fill", title: "答题策略", english: "How to Approach This Topic")

            // Tips
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

            // Prompt reminder
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

            // Pass criteria reminder
            sectionHeader(icon: "target", title: "过关标准", english: "Pass Criteria")

            VStack(alignment: .leading, spacing: 8) {
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
        }
    }

    private func sectionHeader(icon: String, title: String, english: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
                Text(english)
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
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

struct VocabularyStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var selectedCategory: VocabCategory = .core
    @State private var selectedItem: VocabItem?
    @State private var showUpgrade = true
    @State private var showAdvanced = false

    private var coreItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .core }
    }

    private var upgradeItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .upgrade }
    }

    private var advancedItems: [VocabItem] {
        task.vocabulary.filter { $0.band == .advanced }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "textbook", title: "词汇学习", english: "Core & Extended Vocabulary")

            Text("点击单词查看发音、解释和例句")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)

            categorySwitcher

            if selectedCategory == .core {
                vocabGroupCard(
                    title: "核心词汇",
                    subtitle: "先掌握这些高频词再进入扩展",
                    color: Color(hex: "4A90D9")
                ) {
                    vocabList(items: coreItems)
                }
            } else {
                extendedSectionCard
            }
        }
        .sheet(item: $selectedItem) { item in
            VocabDetailSheet(item: item, accentColor: accentColor)
        }
    }

    private func sectionHeader(icon: String, title: String, english: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
                Text(english)
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
    }

    private var categorySwitcher: some View {
        HStack(spacing: 10) {
            ForEach(VocabCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                let count = category == .core ? coreItems.count : (upgradeItems.count + advancedItems.count)

                Button {
                    withAnimation(.spring(duration: 0.28)) {
                        selectedCategory = category
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
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .cardShadow()
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

    private func vocabGroupCard<Content: View>(
        title: String,
        subtitle: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Spacer()
                Text("\(coreItems.count)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)

            content()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .cardShadow()
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
                        Text(item.phonetic)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColors.secondText)

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

                Text(item.band.bandLabel)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.band.color.opacity(0.16), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.band.color.opacity(0.65))
                .frame(width: 4, height: 28)
                .padding(.leading, 8)
        }
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
                            Text(item.phonetic)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.tertiaryText)
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

                        Text(item.englishMeaning)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondText)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("例句")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                        Text(item.example)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                        Text(item.exampleTranslation)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()
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

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, locale: String, rate: Float) {
        guard !text.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.02
        synthesizer.speak(utterance)
    }
}

// MARK: - Phrases Step
struct PhrasesStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "text.quote")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("实用词组")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    Text("Useful Phrases & Examples")
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            ForEach(task.phrases) { phrase in
                VStack(alignment: .leading, spacing: 8) {
                    Text(phrase.phrase)
                        .font(.subheadline.bold())
                        .foregroundStyle(accentColor)

                    Text(phrase.example)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                        .italic()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
                .cardShadow()
            }
        }
    }
}

// MARK: - Framework Step
struct FrameworkStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    private let labels = ["开场", "来源", "使用", "例子", "收尾"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("表达框架")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    Text("Expression Framework")
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(task.frameworkSentences.enumerated()), id: \.offset) { index, sentence in
                    HStack(alignment: .top, spacing: 14) {
                        // Step indicator
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 28, height: 28)
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                            if index < task.frameworkSentences.count - 1 {
                                Rectangle()
                                    .fill(accentColor.opacity(0.2))
                                    .frame(width: 2, height: 40)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if index < labels.count {
                                Text(labels[index])
                                    .font(.caption.bold())
                                    .foregroundStyle(accentColor)
                            }
                            Text(sentence)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryText)
                                .padding(.bottom, index < task.frameworkSentences.count - 1 ? 16 : 0)
                        }
                        .padding(.top, 3)
                    }
                }
            }
            .padding(16)
            .cardStyle()

            // Upgrade expressions
            if !task.upgradeExpressions.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "F59E0B"))
                    Text("升级表达")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(Array(task.upgradeExpressions.enumerated()), id: \.offset) { _, pair in
                        VStack(alignment: .leading, spacing: 6) {
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
                    }
                }
            }
        }
    }
}

// MARK: - Samples Step
struct SamplesStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    @State private var selectedBand = 0

    private var bandColors: [Color] {
        [Color(hex: "4A90D9"), Color(hex: "F59E0B"), Color(hex: "EF4444")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "doc.richtext.fill")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("范文学习")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    Text("Sample Answers")
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
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

                    Text(sample.content)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryText)
                        .lineSpacing(6)

                    // Audio button placeholder
                    Button {} label: {
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
            }
        }
    }
}

// MARK: - Practice Prompt
struct PracticePromptView: View {
    let task: SpeakingTask
    let accentColor: Color

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)

            // Practice icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 68, height: 68)
                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor)
            }

            Text("口语练习")
                .font(.title3.bold())
                .foregroundStyle(AppColors.primaryText)

            Text("是时候开口说了！")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)

            // Topic card
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

            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                practiceInstruction(num: 1, text: "用中文组织你的想法")
                practiceInstruction(num: 2, text: "点击按钮，将中文翻译成英文")
                practiceInstruction(num: 3, text: "大声朗读你的英文回答")
                practiceInstruction(num: 4, text: "对比范文，找到差距")
            }
            .padding(16)
            .cardStyle()

            // Practice hint
            Text("完成这一步后，将解锁下一个任务")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
    }

    private func practiceInstruction(num: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(num)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
        }
    }
}
