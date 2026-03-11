import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                Text("DailySpeak")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

                VStack(alignment: .leading, spacing: 16) {
                    onboardingItem(icon: "rectangle.stack.fill", title: "Stage-based path", detail: "Follow 9 speaking stages in a clear order.")
                    onboardingItem(icon: "sparkles", title: "AI support", detail: "Translate, polish, and listen back through the server.")
                    onboardingItem(icon: "mic.fill", title: "Speak naturally", detail: "Use voice capture only when you need it.")
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "1A1714"))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
    }

    private func onboardingItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "4F6BED"))
                .frame(width: 36, height: 36)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
            }
        }
    }
}
