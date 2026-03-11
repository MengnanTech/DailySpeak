import Foundation
import StoreKit
import UIKit

final class ReviewPromptService {
    static let shared = ReviewPromptService()

    private let defaults = UserDefaults.standard
    private let lastRequestKey = "dailyspeak.reviewPrompt.lastRequestDate"
    private let cooldownDays = 90

    private init() {}

    @MainActor
    func requestReviewManually() {
        requestReview(force: true)
    }

    @MainActor
    func requestReviewIfAppropriate() {
        requestReview(force: false)
    }

    @MainActor
    private func requestReview(force: Bool) {
        if !force, let last = defaults.object(forKey: lastRequestKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            if days < cooldownDays {
                return
            }
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
        defaults.set(Date(), forKey: lastRequestKey)
    }
}
