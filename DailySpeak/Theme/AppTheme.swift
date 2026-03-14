import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Colors
enum AppColors {
    static let background   = Color(hex: "F5F3EF")
    static let card         = Color.white
    static let surface      = Color(hex: "F0EDE8")
    static let border       = Color(hex: "E8E3DB")

    static let primaryText  = Color(hex: "1A1714")
    static let secondText   = Color(hex: "6B6560")
    static let tertiaryText = Color(hex: "9E9890")

    static let success      = Color(hex: "34D399")
    static let warning      = Color(hex: "FBBF24")

    // Warm neutral shadow color
    static let shadowColor  = Color(hex: "B0A89E")
}

// MARK: - Stage Theme
struct StageTheme {
    let start: String
    let end: String
    let emoji: String

    var startColor: Color { Color(hex: start) }
    var endColor: Color   { Color(hex: end) }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [startColor, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var softGradient: LinearGradient {
        LinearGradient(
            colors: [startColor.opacity(0.9), endColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static let all: [StageTheme] = [
        // 1 — Royal Blue (不改)
        StageTheme(start: "4F6BED", end: "7B8FF5", emoji: "📝"),
        // 2 — Soft Sky
        StageTheme(start: "4A90D9", end: "7AB4E8", emoji: "🌅"),
        // 3 — Lilac
        StageTheme(start: "9B72CF", end: "B896E0", emoji: "👤"),
        // 4 — Blush Rose
        StageTheme(start: "D66B8F", end: "E899B2", emoji: "🏙️"),
        // 5 — Honey Gold
        StageTheme(start: "C89B3C", end: "DCBC6A", emoji: "⭐"),
        // 6 — Mint
        StageTheme(start: "3DA88A", end: "6AC4AA", emoji: "🎬"),
        // 7 — Dusk Indigo
        StageTheme(start: "6670A8", end: "8C94C8", emoji: "🎓"),
        // 8 — Warm Coral
        StageTheme(start: "CC7E6A", end: "E0A898", emoji: "🌍"),
        // 9 — Mocha
        StageTheme(start: "A0826C", end: "BC9E8C", emoji: "🎯"),
    ]
}

// MARK: - View Modifiers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    func heroShadow(color hex: String = "1A1714") -> some View {
        self.shadow(color: Color(hex: hex).opacity(0.3), radius: 20, x: 0, y: 10)
    }

    func cardStyle() -> some View {
        self
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .cardShadow()
    }

}

// MARK: - Step Section Label
struct StepSectionLabel: View {
    let icon: String
    let title: String
    let color: Color
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppColors.primaryText)
            if let trailing {
                Spacer()
                Text(trailing)
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Gradient Accent Card
struct GradientAccentCard<Content: View>: View {
    let color: Color
    var spacing: CGFloat = 14
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradient(
                colors: [color.opacity(0.5), color.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: spacing) {
                content()
            }
            .padding(18)
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: color.opacity(0.08), radius: 10, x: 0, y: 4)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Numbered Item Row
struct NumberedItemRow: View {
    let index: Int
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: color.opacity(0.25), radius: 3, x: 0, y: 1)
                Text("\(index)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surface.opacity(0.5))
        )
    }
}
