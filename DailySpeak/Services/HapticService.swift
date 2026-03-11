import UIKit

final class HapticService {
    static let shared = HapticService()

    private init() {}

    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
