import SwiftUI

struct ProfileHeaderCard: View {
    let displayName: String?
    let subtitle: String
    let primaryStatTitle: String
    let primaryStatValue: String
    let secondaryStatTitle: String
    let secondaryStatValue: String
    let themeColor: Color
    let showsVIPCrown: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.18))
                            .frame(width: 70, height: 70)

                        Circle()
                            .stroke(themeColor.opacity(0.35), lineWidth: 1)
                            .frame(width: 70, height: 70)

                        Text(initials)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(themeColor)
                    }

                    if showsVIPCrown {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LinearGradient.goldGradient)
                            .padding(6)
                            .background(Circle().fill(Color.backgroundCard))
                            .overlay(
                                Circle()
                                    .stroke(Color.primaryAmber.opacity(0.45), lineWidth: 1)
                            )
                            .offset(x: 6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.headline)
                        .foregroundColor(.textSecondary)

                    Text(displayName ?? "Guest")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textMuted)
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
                    color: .primaryAmber
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusHero, style: .continuous)
                .fill(Color.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusHero, style: .continuous)
                        .fill(LinearGradient.cardGradient)
                        .opacity(0.25)
                )
        )
        .shadowSubtle()
    }

    private var initials: String {
        if let name = displayName, let first = name.first {
            return String(first)
        }
        return "D"
    }
}

struct ProfileStatBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.16))
        )
    }
}

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
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusCard, style: .continuous)
                .fill(Color.backgroundCard)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusCard, style: .continuous))
        .shadowStandard()
    }
}

struct NavigationMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 12) {
            SettingRow(icon: icon, title: title, subtitle: subtitle, iconColor: iconColor)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

struct ActionMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    var trailingIcon: String? = nil
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 12) {
            SettingRow(icon: icon, title: title, subtitle: subtitle, isDestructive: isDestructive, iconColor: iconColor)

            Spacer()

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    var iconColor: Color? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isDestructive ? .error : (iconColor ?? .textPrimary))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .error : .textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.textMuted)
                }
            }
        }
    }
}
