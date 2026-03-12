import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var selection = 0
    @State private var isFinishing = false

    private let pages: [OnboardingPage] = [
        .init(
            title: "Build speaking confidence in stages",
            subtitle: "Move through 9 carefully structured speaking stages instead of practicing random prompts.",
            icon: "square.stack.3d.up.fill",
            accent: Color(hex: "4F6BED")
        ),
        .init(
            title: "Use AI as a speaking partner",
            subtitle: "Translate ideas, polish spoken English, and review clearer answers before you speak them out loud.",
            icon: "sparkles.rectangle.stack.fill",
            accent: Color(hex: "C89B3C")
        ),
        .init(
            title: "Enable reminders only when you want them",
            subtitle: "Microphone, speech, and notifications are requested only when their features are used.",
            icon: "bell.badge.fill",
            accent: Color(hex: "3DA88A")
        )
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(page.accent.opacity(0.12))
                                    .frame(width: 220, height: 220)

                                Image(systemName: page.icon)
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundStyle(page.accent)
                            }

                            VStack(spacing: 12) {
                                Text(page.title)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryText)
                                    .multilineTextAlignment(.center)

                                Text(page.subtitle)
                                    .font(.body)
                                    .foregroundStyle(AppColors.secondText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 12)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == selection ? pages[index].accent : AppColors.border)
                                .frame(width: index == selection ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.78), value: selection)
                        }
                    }

                    Button {
                        if selection < pages.count - 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                selection += 1
                            }
                        } else {
                            finishOnboarding()
                        }
                    } label: {
                        Text(selection == pages.count - 1 ? (isFinishing ? "Preparing..." : "Start DailySpeak") : "Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(pages[selection].accent, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(isFinishing)

                    Button("Skip for now") {
                        finishOnboarding()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.secondText)
                    .disabled(isFinishing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func finishOnboarding() {
        guard !isFinishing else { return }
        isFinishing = true
        Task {
            let granted = await NotificationService.shared.requestPermission()
            await MainActor.run {
                if granted {
                    PushNotificationService.shared.registerForRemoteNotificationsIfPossible()
                }
                isPresented = false
                isFinishing = false
            }
        }
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
