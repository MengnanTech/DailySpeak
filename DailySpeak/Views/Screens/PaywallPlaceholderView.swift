import SwiftUI

struct PaywallPlaceholderView: View {
    @State private var appeared = false
    @State private var shimmer = false

    private let gold = Color(hex: "C89B3C")
    private let goldLight = Color(hex: "DCBC6A")

    private let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("waveform.path.ecg", "Speaking Packs", "Unlock premium AI-powered speaking drills and personalized feedback."),
        ("person.crop.rectangle.stack.fill", "Account Upgrades", "Sync progress across devices and unlock advanced analytics."),
        ("sparkles", "Smart Review", "AI-driven review sessions that adapt to your weak points."),
        ("globe", "Native Content", "Access curated native-speaker content and pronunciation guides.")
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    premiumHeader
                        .staggerIn(index: 0, appeared: appeared)

                    ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                        benefitCard(icon: benefit.icon, title: benefit.title, subtitle: benefit.subtitle)
                            .staggerIn(index: index + 1, appeared: appeared)
                    }

                    subscribeButton
                        .staggerIn(index: benefits.count + 1, appeared: appeared)

                    legalLinks
                        .staggerIn(index: benefits.count + 2, appeared: appeared)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appeared = true }
    }

    // MARK: - Premium Header
    private var premiumHeader: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [gold, goldLight, gold.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.2), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 250
                    )
                )

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 120)
                    .blur(radius: 2)
                    .offset(x: geo.size.width - 65, y: -35)
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 80)
                    .offset(x: -20, y: geo.size.height - 30)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DAILYSPEAK")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(2)

                        Text("Premium")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, options: .repeating.speed(0.4))
                    }
                }

                Text("Unlock the full DailySpeak experience with premium features designed to accelerate your speaking journey.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(3)
            }
            .padding(22)
        }
        .frame(minHeight: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: gold.opacity(0.25), radius: 20, x: 0, y: 10)
    }

    // MARK: - Benefit Card
    private func benefitCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.12), gold.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(gold)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.border.opacity(0.4), lineWidth: 0.5)
        )
        .cardShadow()
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        VStack(spacing: 10) {
            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Coming Soon")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [gold, goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: gold.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.7)

            Text("Premium features are under development")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
        }
    }

    // MARK: - Legal Links
    private var legalLinks: some View {
        HStack(spacing: 20) {
            if let privacyURL = URL(string: Constants.privacyPolicyURL) {
                Link("Privacy Policy", destination: privacyURL)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.tertiaryText)
            }
            if let termsURL = URL(string: Constants.termsOfServiceURL) {
                Link("Terms of Service", destination: termsURL)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaywallPlaceholderView()
    }
}
