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

    static let success      = Color(hex: "10B981")
    static let warning      = Color(hex: "F59E0B")
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

    var lightGradient: LinearGradient {
        LinearGradient(
            colors: [startColor.opacity(0.12), endColor.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let all: [StageTheme] = [
        StageTheme(start: "4A90D9", end: "2E6DB4", emoji: "📝"),
        StageTheme(start: "10B981", end: "059669", emoji: "🌅"),
        StageTheme(start: "8B5CF6", end: "7C3AED", emoji: "👤"),
        StageTheme(start: "F59E0B", end: "D97706", emoji: "🏙️"),
        StageTheme(start: "EC4899", end: "DB2777", emoji: "⭐"),
        StageTheme(start: "14B8A6", end: "0D9488", emoji: "🎬"),
        StageTheme(start: "6366F1", end: "4F46E5", emoji: "🎓"),
        StageTheme(start: "EF4444", end: "DC2626", emoji: "🌍"),
        StageTheme(start: "F97316", end: "EA580C", emoji: "🎯"),
    ]
}

// MARK: - View Modifiers
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color(hex: "1A1714").opacity(0.06), radius: 10, x: 0, y: 3)
    }

    func heroShadow(color hex: String) -> some View {
        self.shadow(color: Color(hex: hex).opacity(0.35), radius: 20, x: 0, y: 10)
    }

    func cardStyle() -> some View {
        self
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .cardShadow()
    }
}
