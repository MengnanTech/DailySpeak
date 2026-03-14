import SwiftUI

struct PracticeView: View {
    @Environment(ProgressManager.self) private var progress
    @Environment(\.dismiss) private var dismiss
    let stage: Stage
    let task: SpeakingTask

    @State private var chineseInput = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var showCompletion = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    private var theme: StageTheme { stage.theme }
    private let speechRate: Float = 0.46

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topicCard
                inputSection
                if !translatedText.isEmpty { translationResult }
                if let errorMessage {
                    errorCard(errorMessage)
                }
                if showCompletion { completionCard }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 60)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Guided Practice")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .onTapGesture { isFocused = false }
        .onDisappear { EnglishSpeechPlayer.shared.stopPlayback() }
    }

    // MARK: - Topic
    private var topicCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(theme.startColor)
                Text("Practice Topic")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }

            Text(task.prompt)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .italic()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.startColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("用中文说出你的想法")
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $chineseInput)
                    .focused($isFocused)
                    .frame(minHeight: 120)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isFocused ? theme.startColor : AppColors.border, lineWidth: 1)
                    )

                if chineseInput.isEmpty {
                    Text("在这里输入你的中文回答...")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            Button {
                translateToEnglish()
            } label: {
                HStack(spacing: 8) {
                    if isTranslating {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.subheadline.bold())
                    }
                    Text(translatedText.isEmpty ? "Translate to English" : "Re-translate")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    chineseInput.isEmpty
                        ? AnyShapeStyle(AppColors.border)
                        : AnyShapeStyle(theme.gradient)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(chineseInput.isEmpty || isTranslating)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Translation Result
    private var translationResult: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(theme.startColor)
                Text("English Translation")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }

            Text(translatedText)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(6)
                .textSelection(.enabled)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.success.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.success.opacity(0.2), lineWidth: 1)
                )

            InlineAudioPlayerControl(
                text: translatedText,
                playbackID: translationPlaybackID,
                sourceLabel: "Practice Translation",
                accentColor: theme.startColor,
                title: "Practice Translation"
            )

            Text("Read the translation aloud and compare with sample answers.")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)

            if !showCompletion {
                Button {
                    withAnimation(.spring(duration: 0.5)) {
                        showCompletion = true
                        progress.completeStep(
                            stageId: stage.id, taskId: task.id, stepIndex: 5
                        )
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline.bold())
                        Text("Mark as Complete")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.success)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .cardStyle()
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Error Card
    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "F59E0B"))
            Text(message)
                .font(.caption)
                .foregroundStyle(AppColors.secondText)
            Spacer()
            Button {
                withAnimation { errorMessage = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColors.tertiaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "FEF3C7"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Completion
    private var completionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.success)

            Text("Great job!")
                .font(.title3.bold())
                .foregroundStyle(AppColors.primaryText)

            Text("You've completed this practice session.")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Back to Tasks")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(theme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .cardStyle()
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Translation Logic
    private func translateToEnglish() {
        isFocused = false
        isTranslating = true
        errorMessage = nil

        Task {
            do {
                let result = try await PracticeAIService.shared.translateToEnglish(
                    nativeText: chineseInput,
                    topic: task.prompt
                )
                withAnimation(.spring(duration: 0.4)) {
                    translatedText = result
                }
            } catch {
                withAnimation {
                    errorMessage = error.localizedDescription
                }
            }
            isTranslating = false
        }
    }

    private var translationPlaybackID: String {
        WordPronouncer.shared.playbackID(
            for: translatedText,
            locale: "en-US",
            rate: speechRate
        )
    }
}

enum InlineAudioPlayerStyle {
    case prominent
    case compact
}

struct InlineAudioPlayerControl: View {
    @ObservedObject private var speechPlayer = EnglishSpeechPlayer.shared

    let text: String
    let playbackID: String
    let sourceLabel: String
    let accentColor: Color
    var title: String? = nil
    var style: InlineAudioPlayerStyle = .prominent
    var onPlay: (() -> Void)? = nil

    @State private var sliderProgress: Double = 0
    @State private var isScrubbing = false
    @State private var resumeAfterScrub = false

    private var isCurrent: Bool { speechPlayer.isCurrent(id: playbackID) }
    private var isLoading: Bool { speechPlayer.isLoading(id: playbackID) }
    private var isPlaying: Bool { speechPlayer.isPlaying(id: playbackID) }
    private var isPaused: Bool { speechPlayer.isPaused(id: playbackID) }
    private var isExpanded: Bool { isCurrent || isLoading || isPaused }
    private var effectiveProgress: Double { isScrubbing ? sliderProgress : (isCurrent ? speechPlayer.progress : 0) }
    private var effectiveCurrentTime: Double { isCurrent ? speechPlayer.currentTime : 0 }
    private var effectiveDuration: Double { isCurrent ? speechPlayer.duration : 0 }
    private var previewText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Group {
            if isExpanded {
                expandedControl
            } else {
                collapsedControl
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isExpanded)
        .onAppear { syncSlider() }
        .onChange(of: speechPlayer.playbackContext?.id) { syncSlider() }
        .onChange(of: speechPlayer.currentTime) { syncSlider() }
        .onChange(of: speechPlayer.duration) { syncSlider() }
    }

    private var collapsedControl: some View {
        Button(action: togglePlayback) {
            HStack(spacing: style == .compact ? 8 : 10) {
                Image(systemName: "play.fill")
                    .font(style == .compact ? .caption.bold() : .subheadline.bold())
                    .foregroundStyle(accentColor)
                    .frame(width: style == .compact ? 30 : 36, height: style == .compact ? 30 : 36)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? sourceLabel)
                        .font(style == .compact ? .caption.bold() : .subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)
                    if style == .prominent {
                        Text("Tap to play with waveform and scrubbing")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }

                Spacer()

                if style == .prominent {
                    Text("Play")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, style == .compact ? 10 : 14)
            .padding(.vertical, style == .compact ? 8 : 12)
            .background(accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: style == .compact ? 12 : 16))
            .overlay(
                RoundedRectangle(cornerRadius: style == .compact ? 12 : 16)
                    .stroke(accentColor.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var expandedControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                AudioWaveformGlyph(
                    tint: accentColor,
                    isAnimating: isPlaying,
                    isLoading: isLoading,
                    compact: style == .compact
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? sourceLabel)
                        .font(style == .compact ? .caption.bold() : .subheadline.bold())
                        .foregroundStyle(AppColors.primaryText)

                    Text(previewText)
                        .font(style == .compact ? .caption : .caption)
                        .foregroundStyle(AppColors.secondText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: togglePlayback) {
                    Image(systemName: isLoading ? "hourglass" : (isPlaying ? "pause.fill" : "play.fill"))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: stopPlayback) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor)
                        .frame(width: 30, height: 30)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Slider(value: sliderBinding, in: 0 ... 1, onEditingChanged: handleScrubbing)
                    .tint(accentColor)
                    .disabled(isLoading || !isCurrent || effectiveDuration <= 0)

                HStack {
                    Text(statusLabel)
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                    Spacer()
                    Text("\(formatTime(effectiveCurrentTime)) / \(formatTime(effectiveDuration))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
        }
        .padding(.horizontal, style == .compact ? 10 : 14)
        .padding(.vertical, style == .compact ? 10 : 12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: style == .compact ? 14 : 16))
        .overlay(
            RoundedRectangle(cornerRadius: style == .compact ? 14 : 16)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { effectiveProgress },
            set: { sliderProgress = $0 }
        )
    }

    private var statusLabel: String {
        if isLoading { return "Loading..." }
        if isPlaying { return "Playing" }
        if isPaused { return "Paused" }
        return "Ready"
    }

    private func togglePlayback() {
        guard !previewText.isEmpty else { return }
        EnglishSpeechPlayer.shared.togglePlayback(
            id: playbackID,
            text: previewText,
            sourceLabel: sourceLabel
        )
        onPlay?()
    }

    private func stopPlayback() {
        guard isCurrent else { return }
        EnglishSpeechPlayer.shared.stopPlayback()
    }

    private func handleScrubbing(_ editing: Bool) {
        isScrubbing = editing
        if editing {
            sliderProgress = isCurrent ? speechPlayer.progress : 0
            resumeAfterScrub = isPlaying
            if isPlaying {
                EnglishSpeechPlayer.shared.pausePlayback()
            }
            return
        }

        EnglishSpeechPlayer.shared.seekPlayback(to: sliderProgress)
        if resumeAfterScrub {
            EnglishSpeechPlayer.shared.resumePlayback()
        }
        resumeAfterScrub = false
    }

    private func syncSlider() {
        guard !isScrubbing else { return }
        sliderProgress = isCurrent ? speechPlayer.progress : 0
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let totalSeconds = Int(seconds.rounded(.down))
        return "\(totalSeconds / 60):" + String(format: "%02d", totalSeconds % 60)
    }
}

struct AudioWaveformGlyph: View {
    let tint: Color
    let isAnimating: Bool
    let isLoading: Bool
    var compact: Bool = false

    @State private var animateBars = false

    private let restingHeights: [CGFloat] = [8, 14, 10, 16]
    private let animatedHeights: [CGFloat] = [18, 9, 20, 12]

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 3 : 4) {
            ForEach(Array(restingHeights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(tint.opacity(index == 1 ? 0.75 : 1))
                    .frame(width: compact ? 3 : 4, height: animateBars ? animatedHeights[index] : height)
                    .animation(animation(delay: Double(index) * 0.08), value: animateBars)
            }
        }
        .frame(width: compact ? 22 : 28, height: compact ? 20 : 22)
        .onAppear { updateAnimationState() }
        .onChange(of: isAnimating) { updateAnimationState() }
        .onChange(of: isLoading) { updateAnimationState() }
    }

    private func animation(delay: Double) -> Animation {
        let isActive = isAnimating || isLoading
        return isActive
            ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(delay)
            : .easeOut(duration: 0.18)
    }

    private func updateAnimationState() {
        animateBars = isAnimating || isLoading
    }
}
