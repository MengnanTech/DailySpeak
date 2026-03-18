import SwiftUI
import StoreKit

struct PaywallPlaceholderView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubPlan: SubPlan = .yearly
    @State private var purchaseMode: PurchaseMode
    @State private var appeared = false
    @State private var glowPhase = false
    @State private var stageUnlocked = false

    /// Optional: which stage the user tried to access (nil = generic paywall)
    let targetStageId: Int?

    init(targetStageId: Int? = nil) {
        self.targetStageId = targetStageId
        self._purchaseMode = State(initialValue: targetStageId != nil ? .stage : .subscribe)
    }

    private enum SubPlan: String, CaseIterable { case weekly, monthly, yearly }
    private enum PurchaseMode: String, CaseIterable {
        case subscribe, stage
        var label: String {
            switch self {
            case .subscribe: return String(localized: "Subscribe All")
            case .stage: return String(localized: "Unlock Individually")
            }
        }
    }

    private let accent = Color(hex: "4F6BED")
    private let accentLight = Color(hex: "7B8FF5")

    private var proTaskCount: Int {
        CourseData.stages.reduce(0) { $0 + $1.taskCount }
    }

    private var selectedSubProduct: Product? {
        switch selectedSubPlan {
        case .weekly:  return subscription.weeklyProduct
        case .monthly: return subscription.monthlyProduct
        case .yearly:  return subscription.yearlyProduct
        }
    }

    private var targetStage: Stage? {
        guard let id = targetStageId else { return nil }
        return CourseData.stages.first { $0.id == id }
    }

    private var features: [(icon: String, color: String, text: String)] {[
        ("book.fill", "4F6BED", String(localized: "Unlock all 9 stages of speaking courses")),
        ("waveform.path", "8B5CF6", String(localized: "AI pronunciation guidance and personalized practice")),
        ("arrow.triangle.2.circlepath", "10B981", String(localized: "Smart review to strengthen weak areas")),
        ("icloud.and.arrow.up.fill", "0EA5E9", String(localized: "Cross-device learning progress sync")),
    ]}

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [accent.opacity(0.03), AppColors.background, AppColors.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if stageUnlocked, let stage = targetStage {
                stageUnlockedOverlay(stage: stage)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroArea
                            .padding(.top, 50)

                        if subscription.isPro {
                            proActiveBanner
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                        } else {
                            // Purchase mode picker (only if we have a target stage)
                            if targetStageId != nil {
                                modePicker
                                    .padding(.horizontal, 24)
                                    .padding(.top, 28)
                            }

                            if purchaseMode == .subscribe || targetStageId == nil {
                                subscribeSection
                            } else {
                                stageSection
                            }

                            trustFooter
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .padding(.bottom, 40)
                        }
                    }
                }
            }

            // Close
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
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowPhase = true }
        }
        .onChange(of: subscription.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .onChange(of: subscription.purchasedStageIDs) { _, newIDs in
            if let stageId = targetStageId, newIDs.contains(stageId) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    stageUnlocked = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Hero
    private var heroArea: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.12), accent.opacity(0)],
                            center: .center, startRadius: 30, endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(glowPhase ? 1.1 : 0.9)

                Circle()
                    .fill(LinearGradient(colors: [accent, accentLight], startPoint: .topLeading, endPoint: .bottomTrailing))
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
                if let stage = targetStage {
                    Text("Unlock \(stage.title)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    Text("Stage \(stage.id) · \(stage.taskCount) lessons")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                } else {
                    Text("Unlock Your Complete Speaking Journey")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                    Text("\(proTaskCount)+ premium courses to systematically improve your speaking")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
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
                Text("PRO Activated")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                Text("All premium content is unlocked")
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

    // MARK: - Mode Picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(PurchaseMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) { purchaseMode = mode }
                } label: {
                    Text(mode.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(purchaseMode == mode ? .white : AppColors.secondText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            purchaseMode == mode
                                ? AnyShapeStyle(LinearGradient(colors: [accent, accentLight], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Subscribe Section
    private var subscribeSection: some View {
        VStack(spacing: 0) {
            // Feature list
            featureList
                .padding(.horizontal, 24)
                .padding(.top, 24)

            // Plan selector
            VStack(spacing: 10) {
                ForEach(SubPlan.allCases, id: \.self) { plan in
                    if let product = subProduct(for: plan) {
                        subPlanRow(plan: plan, product: product)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            // Error
            if let error = subscription.purchaseError {
                Text(error)
                    .font(.caption).foregroundStyle(.red)
                    .padding(.horizontal, 24).padding(.top, 8)
            }

            // CTA
            purchaseButton(
                title: "Subscribe Now",
                product: selectedSubProduct
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("Cancel anytime · Auto-renew")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.tertiaryText)
                .padding(.top, 10)
        }
    }

    // MARK: - Stage Section
    private var stageSection: some View {
        VStack(spacing: 0) {
            if let stageId = targetStageId, let stage = targetStage {
                // Stage info card
                stageInfoCard(stage: stage)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // Stage purchase button
                if let product = subscription.stageProduct(for: stageId) {
                    purchaseButton(
                        title: "Unlock \(stage.title)  \(product.displayPrice)",
                        product: product
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Text("One-time purchase, lifetime access")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.tertiaryText)
                        .padding(.top, 10)
                }

                // Upsell: subscribe for all
                upsellBanner
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
            }
        }
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
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.08), value: appeared)

                if index < features.count - 1 {
                    Divider().background(AppColors.border.opacity(0.5)).padding(.leading, 50)
                }
            }
        }
    }

    // MARK: - Sub Plan Row
    private func subPlanRow(plan: SubPlan, product: Product) -> some View {
        let isSelected = selectedSubPlan == plan

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedSubPlan = plan }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : AppColors.border, lineWidth: isSelected ? 0 : 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(accent).frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(planTitle(plan))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                        if plan == .yearly {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(LinearGradient(colors: [accent, accentLight], startPoint: .leading, endPoint: .trailing)))
                        }
                    }
                    if plan == .yearly, let yearly = subscription.yearlyProduct {
                        Text(monthlyEquivalent(yearly))
                            .font(.caption).foregroundStyle(AppColors.tertiaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? accent : AppColors.secondText)
                    Text(periodLabel(plan))
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
                    .stroke(isSelected ? accent.opacity(0.5) : AppColors.border.opacity(0.4), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stage Info Card
    private func stageInfoCard(stage: Stage) -> some View {
        HStack(spacing: 14) {
            Text(stage.theme.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("Stage \(stage.id) · \(stage.title)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text(stage.description)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(stage.theme.startColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(stage.theme.startColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Upsell Banner
    private var upsellBanner: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { purchaseMode = .subscribe }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Subscribe PRO to unlock all stages")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                    if let weekly = subscription.weeklyProduct {
                        Text("As low as \(weekly.displayPrice)/week")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.tertiaryText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accent.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button
    private func purchaseButton(title: String, product: Product?) -> some View {
        VStack(spacing: 0) {
            Button {
                guard let product else { return }
                Task { await subscription.purchase(product) }
            } label: {
                HStack(spacing: 8) {
                    if subscription.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(LinearGradient(colors: [accent, accentLight], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: accent.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(product == nil || subscription.isLoading)
            .opacity(product == nil ? 0.5 : 1)

            if subscription.products.isEmpty {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("Loading...")
                        .font(.caption).foregroundStyle(AppColors.tertiaryText)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Trust Footer
    private var trustFooter: some View {
        VStack(spacing: 16) {
            Button {
                Task { await subscription.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accent)
            }
            .disabled(subscription.isLoading)

            HStack(spacing: 12) {
                if let url = URL(string: Constants.privacyPolicyURL) {
                    Link("Privacy Policy", destination: url)
                }
                Text("·")
                if let url = URL(string: Constants.termsOfServiceURL) {
                    Link("Terms of Use", destination: url)
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(AppColors.tertiaryText)
        }
    }

    // MARK: - Stage Unlocked Overlay
    private func stageUnlockedOverlay(stage: Stage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [stage.theme.startColor.opacity(0.15), stage.theme.startColor.opacity(0)],
                            center: .center, startRadius: 30, endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [stage.theme.startColor, stage.theme.endColor],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: stage.theme.startColor.opacity(0.35), radius: 24, x: 0, y: 12)

                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .transition(.scale(scale: 0.3).combined(with: .opacity))

            VStack(spacing: 10) {
                Text("Unlocked!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)

                Text("\(stage.title) is unlocked. Start practicing!")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
                    .multilineTextAlignment(.center)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func subProduct(for plan: SubPlan) -> Product? {
        switch plan {
        case .weekly:  return subscription.weeklyProduct
        case .monthly: return subscription.monthlyProduct
        case .yearly:  return subscription.yearlyProduct
        }
    }

    private func planTitle(_ plan: SubPlan) -> String {
        switch plan {
        case .weekly:  return String(localized: "Weekly")
        case .monthly: return String(localized: "Monthly")
        case .yearly:  return String(localized: "Yearly")
        }
    }

    private func periodLabel(_ plan: SubPlan) -> String {
        switch plan {
        case .weekly:  return String(localized: "/week")
        case .monthly: return String(localized: "/month")
        case .yearly:  return String(localized: "/year")
        }
    }

    private func monthlyEquivalent(_ yearly: Product) -> String {
        let monthly = yearly.price / 12
        let formatted = String(format: "%.2f", NSDecimalNumber(decimal: monthly).doubleValue)
        return String(localized: "About \(formatted)/month, save 55%")
    }
}

#Preview {
    PaywallPlaceholderView(targetStageId: 3)
        .environment(SubscriptionManager())
}
