import SwiftUI

struct TranslateButton: View {
    let englishText: String
    var accentColor: Color = .blue
    var showInline: Bool = true

    @State private var cache = TranslationCache.shared
    @State private var errorMessage: String?

    private var key: String { englishText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasCached: Bool { cache.cached(key) != nil }
    private var isLoading: Bool { cache.isLoading(key) }
    private var isExpanded: Bool { cache.visibleKeys.contains(key) }

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
                    Text(isExpanded ? "收起" : "翻译")
                        .font(.system(size: 12, weight: .medium))
                }
                .fixedSize()
                .foregroundStyle(isExpanded ? .white : accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isExpanded ? accentColor : accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            if showInline, isExpanded, let chinese = cache.cached(key) {
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
            if isExpanded {
                cache.visibleKeys.remove(key)
            } else {
                cache.visibleKeys.insert(key)
            }
            return
        }
        Task {
            do {
                _ = try await cache.translate(key)
                cache.visibleKeys.insert(key)
                errorMessage = nil
            } catch {
                errorMessage = "翻译失败"
            }
        }
    }
}

/// Shows translation text below original content. Pair with TranslateButton(showInline: false).
struct TranslationOverlay: View {
    let englishText: String
    var accentColor: Color = .blue

    @State private var cache = TranslationCache.shared

    private var key: String { englishText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isVisible: Bool { cache.visibleKeys.contains(key) }

    var body: some View {
        if isVisible, let chinese = cache.cached(key) {
            Text(chinese)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isVisible)
        }
    }
}
