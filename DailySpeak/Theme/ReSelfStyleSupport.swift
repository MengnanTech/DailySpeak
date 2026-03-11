import SwiftUI

enum DesignTokens {
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusCard: CGFloat = 20
    static let cornerRadiusHero: CGFloat = 26
}

extension Color {
    static func adaptive(light: String, dark: String) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(hex: hex)
            }
        )
    }

    static let primaryCyan = Color.adaptive(light: "3BB273", dark: "6FD9A4")
    static let primaryGreen = Color.adaptive(light: "00A6A6", dark: "5CD0D0")
    static let primaryAmber = Color.adaptive(light: "FFD166", dark: "FFE39A")

    static let backgroundDark = Color.adaptive(light: "F7F7F7", dark: "000000")
    static let backgroundCard = Color.adaptive(light: "FFFFFF", dark: "1C1C1E")
    static let backgroundSecondary = Color.adaptive(light: "E8E8ED", dark: "2C2C2E")

    static let textPrimary = Color.adaptive(light: "1C1C1E", dark: "F2F2F7")
    static let textSecondary = Color.adaptive(light: "6C6C70", dark: "AEAEB2")
    static let textMuted = Color.adaptive(light: "AEAEB2", dark: "636366")
    static let inkDark = Color(hex: "000000")

    static let success = Color.adaptive(light: "34C759", dark: "30D158")
    static let warning = Color.adaptive(light: "FF9500", dark: "FF9F0A")
    static let error = Color.adaptive(light: "FF3B30", dark: "FF453A")
    static let info = Color.adaptive(light: "007AFF", dark: "0A84FF")
}

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.primaryCyan, Color.primaryGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color.primaryAmber, Color.primaryGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.backgroundCard.opacity(0.8), Color.backgroundSecondary.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private struct StaggeredEntranceModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false

    private var offsetAmount: CGFloat { 20 + min(CGFloat(index) * 7, 30) }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offsetAmount)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.05)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredEntrance(index: Int) -> some View {
        modifier(StaggeredEntranceModifier(index: index))
    }

    func shadowSubtle() -> some View {
        shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }

    func shadowStandard() -> some View {
        shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

