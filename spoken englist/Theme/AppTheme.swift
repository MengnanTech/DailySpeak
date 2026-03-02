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

    var lightGradient: LinearGradient {
        LinearGradient(
            colors: [startColor.opacity(0.12), endColor.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let all: [StageTheme] = [
        StageTheme(start: "5B9BF0", end: "3B6FD4", emoji: "📝"),
        StageTheme(start: "34D399", end: "10B981", emoji: "🌅"),
        StageTheme(start: "A78BFA", end: "8B5CF6", emoji: "👤"),
        StageTheme(start: "FBBF24", end: "F59E0B", emoji: "🏙️"),
        StageTheme(start: "F472B6", end: "EC4899", emoji: "⭐"),
        StageTheme(start: "2DD4BF", end: "14B8A6", emoji: "🎬"),
        StageTheme(start: "818CF8", end: "6366F1", emoji: "🎓"),
        StageTheme(start: "FB7185", end: "F43F5E", emoji: "🌍"),
        StageTheme(start: "FB923C", end: "F97316", emoji: "🎯"),
    ]
}

// MARK: - View Modifiers
extension View {
    /// Card shadow — matches DailySpeak style
    func cardShadow() -> some View {
        self.shadow(color: Color(hex: "1A1714").opacity(0.06), radius: 10, x: 0, y: 3)
    }

    /// Hero shadow — colored tint for depth
    func heroShadow(color hex: String = "1A1714") -> some View {
        self.shadow(color: Color(hex: hex).opacity(0.38), radius: 20, x: 0, y: 10)
    }

    func cardStyle() -> some View {
        self
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .cardShadow()
    }
}
