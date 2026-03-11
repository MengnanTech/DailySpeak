import SwiftUI

struct PaywallPlaceholderView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DailySpeak Premium")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)

                            Text("Placeholder shell only")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color(hex: "B54708"))
                        }

                        Spacer()

                        Circle()
                            .fill(Color(hex: "C89B3C").opacity(0.16))
                            .frame(width: 58, height: 58)
                            .overlay(
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color(hex: "C89B3C"))
                            )
                    }

                    Text("This round only keeps the paywall entry, structure, and future placeholder page. Real StoreKit products and purchase flow are intentionally not implemented yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)
                }
                .padding(20)
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: 28))
                .cardShadow()

                benefit(title: "Future speaking packs", subtitle: "Reserved area for premium speaking drills or AI-backed features.")
                benefit(title: "Account-level upgrades", subtitle: "Keeps the product shell ready without forcing subscription logic into this migration.")
                benefit(title: "Legal links remain visible", subtitle: "The page still surfaces stable privacy and terms destinations.")

                VStack(spacing: 10) {
                    if let privacyURL = URL(string: Constants.privacyPolicyURL) {
                        Link("Privacy Policy", destination: privacyURL)
                    }
                    if let termsURL = URL(string: Constants.termsOfServiceURL) {
                        Link("Terms of Service", destination: termsURL)
                    }
                }
                .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func benefit(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "C89B3C").opacity(0.14))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color(hex: "C89B3C"))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondText)
            }

            Spacer()
        }
        .padding(18)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 22))
        .cardShadow()
    }
}

#Preview {
    NavigationStack {
        PaywallPlaceholderView()
    }
}
