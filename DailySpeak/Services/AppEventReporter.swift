import Foundation

enum AppEventName: String {
    case appLaunch = "app_launch"
    case onboardingCompleted = "onboarding_completed"
    case guestModeSelected = "guest_mode_selected"
    case authSucceeded = "auth_succeeded"
    case signedOut = "signed_out"
    case audioUploadCompleted = "audio_upload_completed"
    case audioUploadFailed = "audio_upload_failed"
}

final class AppEventReporter {
    static let shared = AppEventReporter()

    private init() {}

    func report(_ event: AppEventName, properties: [String: String] = [:]) {
        Task.detached(priority: .background) {
            let body = await MainActor.run {
                let payload = AppEventPayload(
                    event: event.rawValue,
                    authMode: AppState.currentAuthModeRawValue,
                    properties: properties
                )
                return try? JSONEncoder().encode(payload)
            }
            _ = try? await APIClient.shared.sendDataRequest(
                "api/dailyspeak/events",
                method: .post,
                jsonBody: body,
                requiresAuth: false,
                contentType: "application/json"
            )
        }
    }
}

private struct AppEventPayload: Encodable {
    let event: String
    let authMode: String
    let properties: [String: String]
}
