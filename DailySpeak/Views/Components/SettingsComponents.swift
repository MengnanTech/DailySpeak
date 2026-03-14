import SwiftUI

// MARK: - Profile Header Card (AppTheme unified)
struct ProfileHeaderCard: View {
    let displayName: String?
    let subtitle: String
    let primaryStatTitle: String
    let primaryStatValue: String
    let secondaryStatTitle: String
    let secondaryStatValue: String
    let themeColor: Color
    let showsVIPCrown: Bool

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [themeColor.opacity(0.25), themeColor.opacity(0.08)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 72, height: 72)

                        Circle()
                            .stroke(themeColor.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 72, height: 72)

                        Text(initials)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(themeColor)
                    }

                    if showsVIPCrown {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "C89B3C"))
                            .padding(5)
                            .background(Circle().fill(AppColors.card))
                            .overlay(Circle().stroke(Color(hex: "C89B3C").opacity(0.3), lineWidth: 1))
                            .offset(x: 6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Welcome back")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.tertiaryText)

                    Text(displayName ?? "Guest")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                ProfileStatBadge(
                    icon: "flame.fill",
                    title: primaryStatTitle,
                    value: primaryStatValue,
                    color: themeColor
                )

                ProfileStatBadge(
                    icon: "crown.fill",
                    title: secondaryStatTitle,
                    value: secondaryStatValue,
                    color: Color(hex: "C89B3C")
                )
            }
        }
        .padding(22)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.card)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [themeColor.opacity(0.06), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
        )
        .cardShadow()
    }

    private var initials: String {
        if let name = displayName, let first = name.first {
            return String(first).uppercased()
        }
        return "D"
    }
}

// MARK: - Profile Stat Badge
struct ProfileStatBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.tertiaryText)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Settings Card (AppTheme)
struct SettingsCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.card)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border.opacity(0.4), lineWidth: 0.5)
        )
        .cardShadow()
    }
}

// MARK: - Navigation Menu Row
struct NavigationMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 14) {
            SettingIconBadge(icon: icon, color: iconColor ?? AppColors.secondText)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.border)
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

// MARK: - Action Menu Row
struct ActionMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    var trailingIcon: String? = nil
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 14) {
            SettingIconBadge(
                icon: icon,
                color: isDestructive ? Color(hex: "EF4444") : (iconColor ?? AppColors.secondText)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isDestructive ? Color(hex: "EF4444") : AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }

            Spacer()

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.border)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

// MARK: - Setting Row (legacy compat)
struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 14) {
            SettingIconBadge(
                icon: icon,
                color: isDestructive ? Color(hex: "EF4444") : (iconColor ?? AppColors.secondText)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isDestructive ? Color(hex: "EF4444") : AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
        }
    }
}

// MARK: - Setting Icon Badge
struct SettingIconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
