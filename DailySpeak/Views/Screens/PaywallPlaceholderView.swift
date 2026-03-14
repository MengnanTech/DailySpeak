import SwiftUI
import StoreKit

struct PaywallPlaceholderView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .yearly

    private enum PlanType { case monthly, yearly }

    private let gold = Color(hex: "C89B3C")
    private let goldLight = Color(hex: "DCBC6A")
    private let goldDark = Color(hex: "9A7B2E")

    private var proTaskCount: Int {
        CourseData.stages.dropFirst().reduce(0) { $0 + $1.taskCount }
    }

    private let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("lock.open.fill", "All 9 Stages", "Unlock premium speaking lessons across 8 advanced stages"),
        ("waveform.path.ecg", "AI Speaking Coach", "Real-time pronunciation feedback and personalized drills"),
        ("arrow.triangle.2.circlepath", "Smart Review", "Adaptive review sessions that target your weak points"),
        ("icloud.fill", "Cloud Sync", "Seamlessly sync your progress across all devices"),
    ]

    private var selectedProduct: Product? {
        selectedPlan == .monthly ? subscription.monthlyProduct : subscription.yearlyProduct
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                        .staggeredEntrance(index: 0)

                    VStack(spacing: 20) {
                        // Already PRO banner
                        if subscription.isPro {
                            proActiveBanner
                                .staggeredEntrance(index: 1)
                        }

                        ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                            benefitCard(icon: benefit.icon, title: benefit.title, subtitle: benefit.subtitle)
                                .staggeredEntrance(index: index + (subscription.isPro ? 2 : 1))
                        }

                        if !subscription.isPro {
                            planSection
                                .staggeredEntrance(index: benefits.count + 1)

                            ctaSection
                                .staggeredEntrance(index: benefits.count + 2)

                            footerSection
                                .staggeredEntrance(index: benefits.count + 3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: subscription.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Already PRO Banner
    private var proActiveBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundStyle(gold)

            VStack(alignment: .leading, spacing: 2) {
                Text("PRO 已激活")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text("您已解锁所有高级内容")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(gold.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [goldDark, gold, goldLight, gold.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [.white.opacity(0.15), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )

            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 180)
                    .blur(radius: 3)
                    .offset(x: geo.size.width - 70, y: -50)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 120)
                    .offset(x: -30, y: geo.size.height - 40)
            }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 72, height: 72)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating.speed(0.3))
                }

                VStack(spacing: 6) {
                    Text("DAILYSPEAK")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(3)

                    Text("PRO")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }

                Text("Unlock the complete speaking journey\nwith \(proTaskCount)+ premium lessons")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 24)
        }
        .frame(minHeight: 280)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(bottomLeading: 32, bottomTrailing: 32)
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                cornerRadii: .init(bottomLeading: 32, bottomTrailing: 32)
            )
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.3), .white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
        )
        .shadow(color: gold.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Benefit Card
    private func benefitCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gold.opacity(0.15), gold.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
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

    // MARK: - Plan Selection
    private var planSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(gold)
                Text("CHOOSE YOUR PLAN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.tertiaryText)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                if let monthly = subscription.monthlyProduct {
                    planCard(
                        title: "Monthly",
                        price: monthly.displayPrice,
                        period: "/month",
                        badge: nil,
                        isSelected: selectedPlan == .monthly
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlan = .monthly
                        }
                    }
                }

                if let yearly = subscription.yearlyProduct {
                    planCard(
                        title: "Yearly",
                        price: yearly.displayPrice,
                        period: "/year",
                        badge: "SAVE 55%",
                        isSelected: selectedPlan == .yearly
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPlan = .yearly
                        }
                    }
                }
            }

            // Error message
            if let error = subscription.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        period: String,
        badge: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [gold, goldLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                } else {
                    Spacer().frame(height: 20)
                }

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.tertiaryText)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? gold : AppColors.secondText)

                    Text(period)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [gold, goldLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(AppColors.border.opacity(0.4)),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
            .shadow(
                color: isSelected ? gold.opacity(0.15) : .clear,
                radius: 12, x: 0, y: 6
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await subscription.purchase(product) }
            } label: {
                HStack(spacing: 8) {
                    if subscription.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Subscribe Now")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [goldDark, gold, goldLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: gold.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(selectedProduct == nil || subscription.isLoading)
            .opacity(selectedProduct == nil ? 0.6 : 1)

            if subscription.products.isEmpty {
                Text("正在加载订阅方案…")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)
            }
        }
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await subscription.restore() }
            } label: {
                if subscription.isLoading {
                    ProgressView()
                        .tint(AppColors.secondText)
                } else {
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.secondText)
                }
            }
            .disabled(subscription.isLoading)

            HStack(spacing: 16) {
                if let privacyURL = URL(string: Constants.privacyPolicyURL) {
                    Link("Privacy Policy", destination: privacyURL)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.tertiaryText)
                }

                Text("·")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryText)

                if let termsURL = URL(string: Constants.termsOfServiceURL) {
                    Link("Terms of Service", destination: termsURL)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            Text("订阅将自动续费，可随时在系统设置中取消")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        PaywallPlaceholderView()
            .environment(SubscriptionManager())
    }
}
