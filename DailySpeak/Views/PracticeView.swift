import SwiftUI
import AVFoundation

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
    @State private var isSpeaking = false
    @FocusState private var isFocused: Bool

    private let synthesizer = AVSpeechSynthesizer()
    private var theme: StageTheme { stage.theme }

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
                Spacer()
                Button {
                    speakTranslation()
                } label: {
                    Image(systemName: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(theme.startColor)
                        .frame(width: 36, height: 36)
                        .background(theme.startColor.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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

    // MARK: - Text-to-Speech
    private func speakTranslation() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }

        let utterance = AVSpeechUtterance(string: translatedText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
        isSpeaking = true
    }
}
