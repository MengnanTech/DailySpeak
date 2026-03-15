import SwiftUI

struct TranslateButton: View {
    let englishText: String
    var accentColor: Color = .blue

    @State private var cache = TranslationCache.shared
    @State private var isExpanded = false
    @State private var errorMessage: String?

    private var key: String { englishText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasCached: Bool { cache.cached(key) != nil }
    private var isLoading: Bool { cache.isLoading(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: handleTap) {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text("翻译")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(isExpanded ? .white : accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isExpanded ? accentColor : accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            if isExpanded, let chinese = cache.cached(key) {
                Text(chinese)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isExpanded)
    }

    private func handleTap() {
        if hasCached {
            isExpanded.toggle()
            return
        }
        Task {
            do {
                _ = try await cache.translate(key)
                isExpanded = true
                errorMessage = nil
            } catch {
                errorMessage = "翻译失败"
            }
        }
    }
}
