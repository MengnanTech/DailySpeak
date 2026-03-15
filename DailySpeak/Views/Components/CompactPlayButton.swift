import SwiftUI

struct CompactPlayButton: View {
    let text: String
    let playbackID: String
    let sourceLabel: String
    let accentColor: Color
    var onPlay: (() -> Void)? = nil

    @ObservedObject private var player = EnglishSpeechPlayer.shared

    private var isPlaying: Bool { player.isPlaying(id: playbackID) }
    private var isPaused: Bool { player.isPaused(id: playbackID) }
    private var isLoading: Bool { player.isLoading(id: playbackID) }
    private var isActive: Bool { isPlaying || isPaused || isLoading }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                player.togglePlayback(id: playbackID, text: text, sourceLabel: sourceLabel)
                onPlay?()
            } label: {
                ZStack {
                    Circle()
                        .fill(isActive ? accentColor : accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)

                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(isActive ? .white : accentColor)
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isActive ? .white : accentColor)
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
