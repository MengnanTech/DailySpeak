import SwiftUI

struct CompactPlayButton: View {
    let text: String
    let playbackID: String
    let sourceLabel: String
    let accentColor: Color
    var onPlay: (() -> Void)? = nil

    @ObservedObject private var player = EnglishSpeechPlayer.shared
    @State private var hasError = false

    private var isPlaying: Bool { player.isPlaying(id: playbackID) }
    private var isPaused: Bool { player.isPaused(id: playbackID) }
    private var isLoading: Bool { player.isLoading(id: playbackID) }
    private var isActive: Bool { isPlaying || isPaused || isLoading }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                hasError = false
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    hasError = true
                    return
                }
                player.togglePlayback(id: playbackID, text: trimmed, sourceLabel: sourceLabel)
                onPlay?()
            } label: {
                ZStack {
                    Circle()
                        .fill(hasError ? Color.red.opacity(0.15) : (isActive ? accentColor : accentColor.opacity(0.1)))
                        .frame(width: 32, height: 32)

                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.white)
                    } else {
                        Image(systemName: hasError ? "exclamationmark.triangle.fill" : (isPlaying ? "pause.fill" : "play.fill"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(hasError ? .red : (isActive ? .white : accentColor))
                    }
                }
            }
            .buttonStyle(.plain)

            if isPlaying {
                AudioBarsView(color: accentColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.5)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPlaying)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLoading)
        .onChange(of: isLoading) { wasLoading, nowLoading in
            // If loading stopped but not playing/paused, it means it failed
            if wasLoading && !nowLoading && !isPlaying && !isPaused {
                hasError = true
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing { hasError = false }
        }
    }
}

struct AudioBarsView: View {
    let color: Color
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 3, height: animating ? CGFloat.random(in: 8...18) : 6)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: animating
                    )
            }
        }
        .frame(height: 18)
        .onAppear { animating = true }
    }
}
