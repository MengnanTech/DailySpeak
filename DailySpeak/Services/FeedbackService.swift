import Foundation
import UIKit

struct FeedbackService {
    struct Payload {
        let subject: String
        let body: String
    }

    static func buildPayload(appState: AppState) -> Payload {
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
        let device = UIDevice.current

        let body = """
        Please describe your issue or suggestion.

        ----
        App: \(Constants.appName)
        Version: \(version) (\(build))
        Device: \(device.model)
        OS: \(device.systemName) \(device.systemVersion)
        AuthMode: \(appState.authMode.rawValue)
        BackendUserID: \(appState.backendUserID ?? "-")
        """
        return Payload(subject: "DailySpeak Feedback v\(version)", body: body)
    }

    static func mailtoURL(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Constants.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
