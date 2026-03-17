import SwiftUI

// MARK: - Toast Model

enum ToastStyle {
    case error
    case warning
    case success

    var icon: String {
        switch self {
        case .error:   "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .error:   Color(hex: "EF4444")
        case .warning: Color(hex: "F59E0B")
        case .success: Color(hex: "34D399")
        }
    }

    var background: Color {
        switch self {
        case .error:   Color(hex: "FEE2E2")
        case .warning: Color(hex: "FEF3C7")
        case .success: Color(hex: "D1FAE5")
        }
    }
}

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let style: ToastStyle
    let message: String

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@Observable
@MainActor
final class ToastManager {
    static let shared = ToastManager()

    private(set) var current: ToastItem?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, style: ToastStyle = .error, duration: TimeInterval = 3.5) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            current = ToastItem(style: style, message: message)
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            current = nil
        }
    }
}

// MARK: - Toast Banner View

struct ToastBannerView: View {
    let item: ToastItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.style.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(item.style.tint)

            Text(item.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(3)

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColors.tertiaryText)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(item.style.background)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - View Modifier

struct ToastOverlayModifier: ViewModifier {
    @State private var toast = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let item = toast.current {
                    ToastBannerView(item: item) {
                        toast.dismiss()
                    }
                    .padding(.top, 8)
                }
            }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}
