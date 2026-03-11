import Foundation
import UIKit
import UserNotifications
import Security
import os

final class PushNotificationService {
    static let shared = PushNotificationService()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.levi.DailySpeak", category: "Push")
    private init() {}

    private let deviceTokenKey = "dailyspeak.push.deviceToken"
    var currentDeviceToken: String? {
        UserDefaults.standard.string(forKey: deviceTokenKey)
    }

    @MainActor
    func registerForRemoteNotificationsIfPossible() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func syncDeviceRegistrationIfPossible() {
        if let token = currentDeviceToken, !token.isEmpty {
            Task {
                await uploadDeviceTokenIfConfigured(token)
            }
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: deviceTokenKey)
        logger.info("APNs device token received (len=\(token.count, privacy: .public))")
#if DEBUG
        logger.info("APNs device token: \(token, privacy: .public)")
#endif
        Task {
            await uploadDeviceTokenIfConfigured(token)
        }
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        let parsed = Self.parseTitleBody(from: userInfo)
        guard let body = parsed.body else { return }
        let title = parsed.title ?? Constants.appName
        let remoteID = (userInfo["id"] as? String) ?? (userInfo["messageId"] as? String)
        let type = ((userInfo["type"] as? String) ?? (userInfo["kind"] as? String) ?? "").lowercased()
        let kind: PushInboxKind = type == "system" ? .system : .other

        let message = PushInboxMessage(title: title, body: body, kind: kind, remoteID: remoteID, rawPayloadJSON: Self.prettyJSONString(from: userInfo))
        Task {
            await PushInboxStore.shared.append(message)
        }
    }

    private func uploadDeviceTokenIfConfigured(_ token: String) async {
        guard APIConfig.isConfigured else { return }
        guard !(APIClient.shared.accessToken ?? "").isEmpty else { return }
        do {
            let authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            let response: APIEnvelope<EmptyDTO> = try await APIClient.shared.request(
                "push/register",
                method: "POST",
                body: [
                    "deviceToken": token,
                    "platform": "ios",
                    "bundleId": Bundle.main.bundleIdentifier ?? "",
                    "environment": currentPushEnvironment,
                    "appVersion": Constants.appVersion,
                    "build": Constants.appBuildNumber,
                    "os": "iOS",
                    "osVersion": UIDevice.current.systemVersion,
                    "deviceModel": deviceModelIdentifier(),
                    "locale": Locale.current.identifier,
                    "language": Locale.preferredLanguages.first ?? Locale.current.language.languageCode?.identifier ?? "",
                    "timeZone": TimeZone.current.identifier,
                    "pushEnabled": authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral,
                    "deviceId": persistentDeviceID()
                ],
                requiresAuth: true
            )
            if response.code != 200 {
                logger.error("Push token upload rejected: code=\(response.code, privacy: .public) msg=\(response.msg ?? "", privacy: .public)")
                return
            }
        } catch {
            logger.error("Failed to upload device token: \(error.localizedDescription, privacy: .public)")
            return
        }
    }

    private var currentPushEnvironment: String {
#if DEBUG
        "development"
#else
        "production"
#endif
    }

    private func persistentDeviceID() -> String {
        let account = "com.dailyspeak.deviceId"
        if let existing = readKeychainString(account: account) {
            return existing
        }
        let generated = UUID().uuidString
        saveKeychainString(generated, account: account)
        return generated
    }

    private func readKeychainString(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func saveKeychainString(_ value: String, account: String) {
        let data = Data(value.utf8)
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = updateQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier.append(Character(UnicodeScalar(UInt8(value))))
        }
    }

    private static func parseTitleBody(from userInfo: [AnyHashable: Any]) -> (title: String?, body: String?) {
        guard let apsAny = userInfo["aps"] else { return (nil, nil) }
        if let aps = apsAny as? [String: Any] {
            if let alert = aps["alert"] as? String {
                return (nil, alert)
            }
            if let alert = aps["alert"] as? [String: Any] {
                return (alert["title"] as? String, alert["body"] as? String)
            }
        }
        return (userInfo["title"] as? String, userInfo["body"] as? String)
    }

    private static func prettyJSONString(from userInfo: [AnyHashable: Any]) -> String? {
        var object: [String: Any] = [:]
        for (key, value) in userInfo {
            object[String(describing: key)] = value
        }
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
