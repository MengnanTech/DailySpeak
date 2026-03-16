import SwiftUI

// MARK: - Guide Button with completion state

/// Guide button that shows whether the guide has been completed.
/// - Not completed: accent color background
/// - Completed: green background with checkmark
struct GuideButton: View {
    let isCompleted: Bool
    let accentColor: Color
    var label: String = "Guide"
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.fill")
                    .font(.system(size: isCompleted ? 10 : 8, weight: .bold))
                Text(isCompleted ? "Learned" : label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .fixedSize()
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isCompleted ? AppColors.success : accentColor)
            .clipShape(Capsule())
            .overlay(alignment: .topTrailing) {
                if !isCompleted {
                    Circle()
                        .fill(Color(hex: "EF4444"))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(Color(hex: "EF4444").opacity(0.4))
                                .frame(width: 16, height: 16)
                                .scaleEffect(isPulsing ? 1.0 : 0.5)
                                .opacity(isPulsing ? 0 : 1)
                        )
                        .offset(x: 2, y: -3)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if !isCompleted {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: isCompleted) { _, completed in
            if completed { isPulsing = false }
        }
    }
}

// MARK: - Audio Task Dot (overlaid on play buttons)

/// Small indicator dot on required audio items. Shows accent dot when unplayed, green checkmark when played.
struct AudioTaskDot: View {
    let isListened: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            if isListened {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 14, height: 14)
                    .background(AppColors.success)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 1.5)
                    )
            }
        }
        .animation(.spring(duration: 0.3), value: isListened)
    }
}
