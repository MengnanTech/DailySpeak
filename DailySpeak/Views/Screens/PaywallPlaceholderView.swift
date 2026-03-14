import SwiftUI
import StoreKit

struct PaywallPlaceholderView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .yearly
    @State private var appeared = false
    @State private var glowPhase = false

    private enum PlanType { case monthly, yearly }

    // Brand
    private let accent = Color(hex: "4F6BED")
    private let accentLight = Color(hex: "7B8FF5")
    private let gold = Color(hex: "D4A844")

    private var proTaskCount: Int {
        CourseData.stages.dropFirst().reduce(0) { $0 + $1.taskCount }
    }

    private var selectedProduct: Product? {
        selectedPlan == .monthly ? subscription.monthlyProduct : subscription.yearlyProduct
    }

    private let features: [(icon: String, color: String, text: String)] = [
        ("book.fill", "4F6BED", "解锁全部 9 个阶段的口语课程"),
        ("waveform.path", "8B5CF6", "AI 发音指导与个性化练习"),
        ("arrow.triangle.2.circlepath", "10B981", "智能复习，针对薄弱环节强化"),
        ("icloud.and.arrow.up.fill", "0EA5E9", "跨设备同步学习进度"),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            LinearGradient(
                colors: [
                    accent.opacity(0.03),
                    AppColors.background,
                    AppColors.background,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero
                    heroArea
                        .padding(.top, 50)

                    if subscription.isPro {
                        proActiveBanner
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                    }

                    // Features
                    featureList
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    if !subscription.isPro {
                        // Plans
                        planSelector
                            .padding(.horizontal, 24)
                            .padding(.top, 32)

                        // CTA
                        ctaButton
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        // Trust
                        trustFooter
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    } else {
                        Spacer(minLength: 40)
                    }
                }
            }

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
        .onChange(of: subscription.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Hero
    private var heroArea: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.12), accent.opacity(0)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPhase ? 1.1 : 0.9)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accent, accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: accent.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "crown.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white)
                    .offset(y: -1)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.6)

            VStack(spacing: 10) {
                Text("解锁完整口语之旅")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

                Text("\(proTaskCount)+ 节精品课程，系统提升你的口语表达")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
    }

    // MARK: - PRO Active
    private var proActiveBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "10B981").opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "10B981"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("PRO 已激活")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                Text("你已解锁所有高级内容")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "10B981").opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Feature List
    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: feature.color))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: feature.color).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(feature.text)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.primaryText)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -30)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.08),
                    value: appeared
                )

                if index < features.count - 1 {
                    Divider()
                        .background(AppColors.border.opacity(0.5))
                        .padding(.leading, 50)
                }
            }
        }
    }

    // MARK: - Plan Selector
    private var planSelector: some View {
        VStack(spacing: 10) {
            // Yearly plan (recommended)
            if let yearly = subscription.yearlyProduct {
                planRow(
                    product: yearly,
                    title: "年度订阅",
                    subtitle: monthlyEquivalent(yearly),
                    badge: "推荐",
                    isSelected: selectedPlan == .yearly
                ) {
                    withAnimation(.spring(response: 0.3)) { selectedPlan = .yearly }
                }
            }

            // Monthly plan
            if let monthly = subscription.monthlyProduct {
                planRow(
                    product: monthly,
                    title: "月度订阅",
                    subtitle: nil,
                    badge: nil,
                    isSelected: selectedPlan == .monthly
                ) {
                    withAnimation(.spring(response: 0.3)) { selectedPlan = .monthly }
                }
            }

            // Error
            if let error = subscription.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appeared)
    }

    private func planRow(
        product: Product,
        title: String,
        subtitle: String?,
        badge: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : AppColors.border, lineWidth: isSelected ? 0 : 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(accent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [accent, accentLight],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                )
                        }
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? accent : AppColors.secondText)
                    Text(product.subscription?.subscriptionPeriod.unit == .year ? "/年" : "/月")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.04) : AppColors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? accent.opacity(0.5) : AppColors.border.opacity(0.4),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Button
    private var ctaButton: some View {
        VStack(spacing: 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await subscription.purchase(product) }
            } label: {
                HStack(spacing: 8) {
                    if subscription.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("立即订阅")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [accent, accentLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: accent.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(selectedProduct == nil || subscription.isLoading)
            .opacity(selectedProduct == nil ? 0.5 : 1)

            if subscription.products.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("加载中…")
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            Text("可随时取消 · 自动续费")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.tertiaryText)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: appeared)
    }

    // MARK: - Trust Footer
    private var trustFooter: some View {
        VStack(spacing: 16) {
            Button {
                Task { await subscription.restore() }
            } label: {
                Text("恢复购买")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accent)
            }
            .disabled(subscription.isLoading)

            HStack(spacing: 12) {
                if let url = URL(string: Constants.privacyPolicyURL) {
                    Link("隐私政策", destination: url)
                }
                Text("·")
                if let url = URL(string: Constants.termsOfServiceURL) {
                    Link("使用条款", destination: url)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(AppColors.tertiaryText)
        }
    }

    // MARK: - Helpers
    private func monthlyEquivalent(_ yearly: Product) -> String {
        let monthly = yearly.price / 12
        let formatted = String(format: "%.2f", NSDecimalNumber(decimal: monthly).doubleValue)
        return "约 ¥\(formatted)/月，节省 55%"
    }
}

#Preview {
    PaywallPlaceholderView()
        .environment(SubscriptionManager())
}
