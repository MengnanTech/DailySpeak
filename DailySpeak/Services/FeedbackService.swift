import Foundation
import UIKit
import MessageUI

struct FeedbackService {
    struct Payload {
        let recipients: [String]
        let subject: String
        let body: String
    }

    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    static func buildPayload(appState: AppState) -> Payload {
        let device = UIDevice.current
        let diagnostics = [
            "App: \(Constants.appName)",
            "Version: \(Constants.appVersion) (\(Constants.appBuildNumber))",
            "Bundle: \(Bundle.main.bundleIdentifier ?? "?")",
            "Device: \(device.model)",
            "OS: \(device.systemName) \(device.systemVersion)",
            "Locale: \(Locale.current.identifier)",
            "Language: \(Locale.preferredLanguages.first ?? "?")",
            "AuthMode: \(appState.authMode.rawValue)",
            "BackendUserID: \(appState.backendUserID ?? "guest")"
        ].joined(separator: "\n")

        return Payload(
            recipients: [Constants.supportEmail],
            subject: "\(Constants.appName) Feedback v\(Constants.appVersion)",
            body: """
            (Describe your issue or suggestion here)

            ----
            Diagnostics
            \(diagnostics)
            """
        )
    }

    static func mailtoURL(to: String, subject: String, body: String) -> URL? {
        guard !to.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
