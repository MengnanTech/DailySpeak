import SwiftUI

struct SplashAnimationView: View {
    var onComplete: () -> Void

    @State private var pulse = false
    @State private var lift = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "F7F1E7"),
                    Color(hex: "EDE4D5"),
                    Color(hex: "F5F3EF")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "4F6BED").opacity(0.12))
                .frame(width: 240, height: 240)
                .scaleEffect(pulse ? 1.15 : 0.82)
                .blur(radius: 6)

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4F6BED"), Color(hex: "7B8FF5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)
                        .rotationEffect(.degrees(lift ? -8 : 8))
                        .shadow(color: Color(hex: "4F6BED").opacity(0.22), radius: 24, x: 0, y: 12)

                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(y: lift ? -8 : 8)

                VStack(spacing: 8) {
                    Text("DailySpeak")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Speak every day. Sound more natural.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.secondText)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
                lift = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_250_000_000)
                await MainActor.run {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashAnimationView {}
}
