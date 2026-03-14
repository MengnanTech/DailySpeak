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
        .navigationBarBackButtonHidden(!isLoaded)
    }
}

// MARK: - Loading Screen

struct TaskLoadingView: View {
    let stage: Stage
    let task: SpeakingTask
    let onReady: () -> Void

    @State private var progress: Double = 0
    @State private var statusText = "准备学习内容..."
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotCount = 0
    @State private var isReady = false

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

                Text(statusText + String(repeating: ".", count: dotCount))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.tertiaryText)
                    .animation(.none, value: dotCount)
            }
            .padding(.horizontal, 50)

            Spacer()
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                .opacity(0) // hide during loading
            }
        }
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
        statusText = "加载课程数据"
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Phase 2: Load TTS audio
        withAnimation { progress = 0.4 }
        statusText = "准备语音内容"

        if !goalText.isEmpty {
            let playbackId = EnglishSpeechPlayer.playbackID(for: goalText, category: "focus-goal")
            let success = await EnglishSpeechPlayer.shared.prepareAudio(id: playbackId, text: goalText)

            if success {
                withAnimation { progress = 0.85 }
                statusText = "语音就绪"
            } else {
                withAnimation { progress = 0.85 }
                statusText = "语音加载失败，继续进入"
            }
        } else {
            withAnimation { progress = 0.85 }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        // Phase 3: Done
        withAnimation { progress = 1.0 }
        statusText = "准备完成"
        try? await Task.sleep(nanoseconds: 400_000_000)

        isReady = true
        onReady()
    }
}
