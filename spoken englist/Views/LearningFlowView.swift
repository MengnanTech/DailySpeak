import SwiftUI

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
struct VocabularyStepView: View {
    let task: SpeakingTask
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "textbook", title: "核心词汇", english: "Key Vocabulary")

            ForEach(VocabItem.BandLevel.allCases, id: \.self) { level in
                let items = task.vocabulary.filter { $0.band == level }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        // Band tag
                        HStack(spacing: 6) {
                            Text(level.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(level.color)
                            Text("(\(level.bandLabel))")
                                .font(.caption2)
                                .foregroundStyle(AppColors.tertiaryText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(level.color.opacity(0.08))
                        .clipShape(Capsule())

                        // Word cards
                        ForEach(items) { item in
                            VocabCardView(item: item)
                        }
                    }
                    .padding(16)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .cardShadow()
                }
            }
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

struct VocabCardView: View {
    let item: VocabItem
    @State private var showPhonetic = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.word)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                if showPhonetic {
                    Text(item.phonetic)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Text(item.meaning)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) { showPhonetic.toggle() }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(item.band.color)
                    .frame(width: 32, height: 32)
                    .background(item.band.color.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
