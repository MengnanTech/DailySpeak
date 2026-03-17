import SwiftUI

// MARK: - Container: Loading → Overview

struct TaskLoadingContainerView: View {
    let stage: Stage
    let task: SpeakingTask
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                TaskOverviewView(stage: stage, task: task)
                    .transition(.opacity)
            } else {
                TaskLoadingView(stage: stage, task: task) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isLoaded = true
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

// MARK: - Loading Screen

struct TaskLoadingView: View {
    let stage: Stage
    let task: SpeakingTask
    let onReady: () -> Void

    @State private var progress: Double = 0
    @State private var statusText = String(localized: "Preparing content...")
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotCount = 0
    @State private var isReady = false
    @State private var loadFailed = false
    @State private var failedCount = 0

    private var theme: StageTheme { stage.theme }
    private var goalText: String {
        task.lessonContent?.topic.learningGoal ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon
            ZStack {
                // Pulse rings
                Circle()
                    .stroke(theme.startColor.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                Circle()
                    .stroke(theme.startColor.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale * 0.95)

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [theme.startColor, theme.endColor],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 64, height: 64)
                    Text(theme.emoji)
                        .font(.system(size: 28))
                }
            }

            Spacer().frame(height: 32)

            // Task title
            Text(task.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
            Text(task.englishTitle)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.tertiaryText)
                .padding(.top, 4)

            Spacer().frame(height: 40)

            // Progress bar
            VStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.startColor.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(colors: [theme.startColor, theme.endColor],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 6)

                Text(statusText + (loadFailed ? "" : String(repeating: ".", count: dotCount)))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(loadFailed ? Color(hex: "EF4444") : AppColors.tertiaryText)
                    .animation(.none, value: dotCount)
            }
            .padding(.horizontal, 50)

            if loadFailed {
                Spacer().frame(height: 24)
                VStack(spacing: 10) {
                    Button {
                        loadFailed = false
                        Task { await runLoading() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .bold))
                            Text("Retry")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 44)
                        .background(theme.startColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        loadFailed = false
                        isReady = true
                        onReady()
                    } label: {
                        Text("Skip, continue")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(loadFailed ? false : true)
        .task {
            await runLoading()
        }
        .onAppear {
            startPulse()
            startDots()
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.12
        }
    }

    private func startDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }

    @MainActor
    private func runLoading() async {
        // Phase 1: Immediate progress for local setup
        withAnimation { progress = 0.2 }
        statusText = String(localized: "Loading course data")
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Phase 2: Prepare intro animation audio
        withAnimation { progress = 0.4 }
        statusText = String(localized: "Preparing voice content")

        // Collect all priority items for intro animation
        var priorityItems: [AudioPreloader.AudioItem] = []

        // Hero prompt
        let heroId = EnglishSpeechPlayer.playbackID(for: task.prompt, category: "hero-prompt")
        priorityItems.append((id: heroId, text: task.prompt))

        // Focus goal
        if !goalText.isEmpty {
            let goalId = EnglishSpeechPlayer.playbackID(for: goalText, category: "focus-goal")
            priorityItems.append((id: goalId, text: goalText))
        }

        // Focus suggestion
        let suggestionText = "Start with strategy, then learn vocabulary and framework, finally practice with samples."
        let suggestionId = EnglishSpeechPlayer.playbackID(for: suggestionText, category: "focus-suggestion")
        priorityItems.append((id: suggestionId, text: suggestionText))

        // Focus angle titles (read during Key Focus animation)
        if let lesson = task.lessonContent {
            for angle in lesson.strategy.angles {
                let id = EnglishSpeechPlayer.playbackID(for: angle.title, category: "focus-angle")
                priorityItems.append((id: id, text: angle.title))
            }
        }

        // Step overviews
        var stepTexts: [String] = []
        for step in task.steps {
            let text = step.title + ". " + step.subtitle
            let id = EnglishSpeechPlayer.playbackID(for: text, category: "step-overview")
            priorityItems.append((id: id, text: text))
            stepTexts.append(text)
        }

        // Combined flow-all (play all steps together)
        if !stepTexts.isEmpty {
            let allText = stepTexts.joined(separator: ". ")
            let allId = EnglishSpeechPlayer.playbackID(for: allText, category: "flow-all")
            priorityItems.append((id: allId, text: allText))
        }

        if !priorityItems.isEmpty {
            // Check how many are already cached
            let uncachedItems = priorityItems.filter { !EnglishSpeechPlayer.shared.isAudioCached(id: $0.id) }

            if uncachedItems.isEmpty {
                // All cached (user pre-downloaded or revisiting) → skip quickly
                withAnimation { progress = 0.85 }
                statusText = String(localized: "Voice ready")
            } else {
                // Use batch API for all uncached items at once, then parallel download
                statusText = String(localized: "Preparing voice 0/\(priorityItems.count)")
                let success = await EnglishSpeechPlayer.shared.preloadBatch(uncachedItems)
                guard !Task.isCancelled else { return }
                let failed = uncachedItems.count - success
                if failed > 0 {
                    failedCount = failed
                    withAnimation { progress = 0.85 }
                    statusText = String(localized: "Voice download failed (\(failed) items)")
                    withAnimation { loadFailed = true }
                    return
                }
                withAnimation { progress = 0.85 }
                statusText = String(localized: "Preparing voice \(priorityItems.count)/\(priorityItems.count)")
            }
        }
        withAnimation { progress = 0.85 }
        statusText = String(localized: "Voice ready")

        // Phase 3: Download remaining guide audio
        let allItems = AudioPreloader.allItems(for: task)
        let uncachedGuide = allItems.filter { !EnglishSpeechPlayer.shared.isAudioCached(id: $0.id) }
        if !uncachedGuide.isEmpty {
            statusText = String(localized: "Preparing learning voice")
            withAnimation { progress = 0.88 }
            let guideSuccess = await EnglishSpeechPlayer.shared.preloadBatch(uncachedGuide)
            guard !Task.isCancelled else { return }
            let guideFailed = uncachedGuide.count - guideSuccess
            if guideFailed > 0 {
                failedCount = guideFailed
                withAnimation { progress = 0.9 }
                statusText = String(localized: "Voice download failed (\(guideFailed) items)")
                withAnimation { loadFailed = true }
                return
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Phase 4: Done
        withAnimation { progress = 1.0 }
        statusText = String(localized: "Preparation complete")
        try? await Task.sleep(nanoseconds: 400_000_000)

        isReady = true
        onReady()
    }

    private func audioItemsForStep(_ stepType: StepType) -> [AudioPreloader.AudioItem] {
        switch stepType {
        case .strategy: return AudioPreloader.strategyItems(for: task)
        case .review:   return AudioPreloader.reviewItems(for: task)
        case .phrases:  return AudioPreloader.phrasesItems(for: task)
        case .framework: return AudioPreloader.frameworkItems(for: task)
        case .samples:  return AudioPreloader.samplesItems(for: task)
        case .vocabulary, .practice: return []
        }
    }
}
