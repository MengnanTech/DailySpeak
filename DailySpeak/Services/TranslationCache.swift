import Foundation
import Observation

@MainActor
@Observable
final class TranslationCache {
    static let shared = TranslationCache()

    private(set) var translations: [String: String] = [:]
    private(set) var loadingKeys: Set<String> = []
    var visibleKeys: Set<String> = []

    private init() {}

    func translate(_ englishText: String) async throws -> String {
        let key = englishText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = translations[key] { return cached }
        loadingKeys.insert(key)
        defer { loadingKeys.remove(key) }
        let result = try await DailySpeakAPIService.shared.translateToNative(englishText: key)
        translations[key] = result
        return result
    }

    func cached(_ englishText: String) -> String? {
        translations[englishText.trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    func isLoading(_ englishText: String) -> Bool {
        loadingKeys.contains(englishText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
