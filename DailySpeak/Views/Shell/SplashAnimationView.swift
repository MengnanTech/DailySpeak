import SwiftUI

struct SplashAnimationView: View {
    var onComplete: () -> Void

    @State private var backgroundDrift = false
    @State private var logoSettled = false
    @State private var showOrbit = false
    @State private var showWordmark = false
    @State private var showTagline = false
    @State private var fadeOut = false

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
                .frame(width: 280, height: 280)
                .scaleEffect(backgroundDrift ? 1.16 : 0.86)
                .offset(x: backgroundDrift ? -38 : 24, y: backgroundDrift ? -96 : -42)
                .blur(radius: 14)

            Circle()
                .fill(Color(hex: "7B8FF5").opacity(0.11))
                .frame(width: 220, height: 220)
                .scaleEffect(backgroundDrift ? 0.92 : 1.12)
                .offset(x: backgroundDrift ? 88 : 26, y: backgroundDrift ? 134 : 78)
                .blur(radius: 20)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(showOrbit ? 0.55 : 0))
                    .frame(width: CGFloat(index == 1 ? 7 : 5), height: CGFloat(index == 1 ? 7 : 5))
                    .offset(particleOffset(for: index))
                    .blur(radius: 0.4)
            }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "4F6BED").opacity(showOrbit ? 0.18 : 0), lineWidth: 1.2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showOrbit ? 1 : 0.76)

                    Circle()
                        .stroke(Color.white.opacity(showOrbit ? 0.5 : 0), lineWidth: 1)
                        .frame(width: 104, height: 104)
                        .scaleEffect(showOrbit ? 1 : 0.82)

                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4F6BED"), Color(hex: "7B8FF5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)
                        .rotationEffect(.degrees(logoSettled ? 0 : 14))
                        .scaleEffect(logoSettled ? 1 : 1.18)
                        .shadow(color: Color(hex: "4F6BED").opacity(0.22), radius: 24, x: 0, y: 12)

                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(logoSettled ? 1 : 0.7)
                }
                .offset(y: logoSettled ? -10 : 26)

                VStack(spacing: 8) {
                    Text("DailySpeak")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                        .opacity(showWordmark ? 1 : 0)
                        .offset(y: showWordmark ? 0 : 14)

                    Text("Speak every day. Sound more natural.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.secondText)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                }
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                backgroundDrift = true
            }

            Task {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.76)) {
                    logoSettled = true
                }

                try? await Task.sleep(nanoseconds: 320_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.55)) {
                        showOrbit = true
                    }
                }

                try? await Task.sleep(nanoseconds: 260_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.45)) {
                        showWordmark = true
                    }
                }

                try? await Task.sleep(nanoseconds: 260_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.40)) {
                        showTagline = true
                    }
                }

                try? await Task.sleep(nanoseconds: 2_300_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        fadeOut = true
                    }
                }

                try? await Task.sleep(nanoseconds: 240_000_000)
                await MainActor.run {
                    onComplete()
                }
            }
        }
    }

    private func particleOffset(for index: Int) -> CGSize {
        switch index {
        case 0:
            return CGSize(width: backgroundDrift ? -60 : -38, height: backgroundDrift ? -74 : -54)
        case 1:
            return CGSize(width: backgroundDrift ? 64 : 40, height: backgroundDrift ? -26 : -12)
        default:
            return CGSize(width: backgroundDrift ? -28 : -8, height: backgroundDrift ? 70 : 48)
        }
    }
}

#Preview {
    SplashAnimationView {}
}
