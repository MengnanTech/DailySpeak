import Foundation
import CryptoKit
import Security

struct Constants {
    static let appName = "DailySpeak"
    static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    static let appBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    static let privacyPolicyURL = "https://ikuon.com/privacy.html"
    static let termsOfServiceURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let supportEmail = "levi.lideng@gmail.com"

    struct StorageKeys {
        static let hasLaunchedBefore = "dailyspeak.hasLaunchedBefore"
    }
}

enum AppleSignInNonce {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status).")
            }

            for byte in bytes where remaining > 0 {
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
