import CryptoKit
import Foundation
import Security

struct Constants {
    static let appName = "DailySpeak"
    static let supportEmail = "levi.lideng@gmail.com"
    static let privacyPolicyURL = "https://ikuon.com/privacy.html"
    static let termsOfServiceURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let supportURL = "https://ikuon.com/support.html"

    struct StorageKeys {
        static let hasLaunchedBefore = "app.hasLaunchedBefore"
        static let notificationsEnabled = "notifications.daily.enabled"
        static let notificationsHour = "notifications.daily.hour"
        static let notificationsMinute = "notifications.daily.minute"
    }
}

enum AppleSignInNonce {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status).")
            }

            for byte in bytes {
                if remaining == 0 { break }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
