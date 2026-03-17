import Foundation
import StoreKit
import UIKit

final class ReviewPromptService {
    static let shared = ReviewPromptService()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private let lastRequestKey = "dailyspeak.reviewPrompt.lastRequestDate"
    private let requestCountKey = "dailyspeak.reviewPrompt.requestCountThisYear"
    private let requestYearKey = "dailyspeak.reviewPrompt.requestYear"
    private let appLaunchCountKey = "dailyspeak.reviewPrompt.appLaunchCount"

    // MARK: - Thresholds
    private let cooldownDays = 90
    private let minCompletedTasks = 3
    private let minAppLaunches = 5
    private let maxRequestsPerYear = 3

    private init() {}

    // MARK: - Public API

    /// Call from app launch (scenePhase → .active) to track launches
    func recordAppLaunch() {
        let count = defaults.integer(forKey: appLaunchCountKey)
        defaults.set(count + 1, forKey: appLaunchCountKey)
    }

    /// Force-show review dialog (settings page "Rate Us" button)
    @MainActor
    func requestReviewManually() {
        presentReviewDialog()
    }

    /// Smart trigger — call after positive moments (task completion, daily goal met)
    @MainActor
    func requestReviewIfAppropriate(completedTaskCount: Int) {
        guard shouldPrompt(completedTaskCount: completedTaskCount) else { return }
        presentReviewDialog()
        recordRequest()
    }

    // MARK: - Decision Logic

    private func shouldPrompt(completedTaskCount: Int) -> Bool {
        // 1. Enough completed tasks to show the user has engaged
        guard completedTaskCount >= minCompletedTasks else { return false }

        // 2. Enough app launches (not a brand-new user)
        guard defaults.integer(forKey: appLaunchCountKey) >= minAppLaunches else { return false }

        // 3. Respect Apple's per-year limit (max 3 prompts/year)
        resetYearlyCountIfNeeded()
        guard defaults.integer(forKey: requestCountKey) < maxRequestsPerYear else { return false }

        // 4. Cooldown since last prompt
        if let last = defaults.object(forKey: lastRequestKey) as? Date {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            if days < cooldownDays { return false }
        }

        return true
    }

    // MARK: - Helpers

    @MainActor
    private func presentReviewDialog() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func recordRequest() {
        defaults.set(Date(), forKey: lastRequestKey)
        resetYearlyCountIfNeeded()
        let count = defaults.integer(forKey: requestCountKey)
        defaults.set(count + 1, forKey: requestCountKey)
    }

    private func resetYearlyCountIfNeeded() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let savedYear = defaults.integer(forKey: requestYearKey)
        if savedYear != currentYear {
            defaults.set(currentYear, forKey: requestYearKey)
            defaults.set(0, forKey: requestCountKey)
        }
    }
}
