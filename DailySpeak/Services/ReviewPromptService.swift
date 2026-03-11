import StoreKit
import UIKit

final class ReviewPromptService {
    static let shared = ReviewPromptService()

    private let defaults = UserDefaults.standard
    private let requestCountKey = "review.request.count"
    private let lastRequestKey = "review.last.request"

    private init() {}

    @MainActor
    func registerLearningMilestone() {
        let newCount = defaults.integer(forKey: requestCountKey) + 1
        defaults.set(newCount, forKey: requestCountKey)
        guard newCount >= 3 else { return }
        requestReviewIfAppropriate()
    }

    @MainActor
    func requestReviewIfAppropriate() {
        if let last = defaults.object(forKey: lastRequestKey) as? Date,
           Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0 < 90 {
            return
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
