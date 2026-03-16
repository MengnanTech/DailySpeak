import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class WebSocketInboxClient {
    static let shared = WebSocketInboxClient()

    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var isStarted = false
    private var retryCount = 0
    private var pingTimer: Timer?
    private static let maxRetryDelay: TimeInterval = 60
    private static let pingInterval: TimeInterval = 30

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    func startIfPossible() {
        guard !isStarted else { return }
        guard APIConfig.isConfigured else {
            print("❌ [WS] API not configured")
            return
        }
        guard let token = APIClient.shared.accessToken, !token.isEmpty else {
            print("❌ [WS] no access token")
            return
        }

        connect(token: token)
    }

    private func connect(token: String) {
        let url = makeWebSocketURL(baseURL: APIConfig.baseURL, accessToken: token)
        print("⬆️ [WS CONNECT] \(url.absoluteString.prefix(80))…")

        let request = URLRequest(url: url)
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true

        let session = URLSession(configuration: configuration)
        self.session = session
        let task = session.webSocketTask(with: request)
        self.task = task
        self.isStarted = true
        task.resume()
        receiveLoop()
        startPing()
    }

    func stop() {
        isStarted = false
        retryCount = 0
        stopPing()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    // MARK: - Ping keep-alive

    private func startPing() {
        stopPing()
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: Self.pingInterval, repeats: true) { [weak self] _ in
                self?.sendPing()
            }
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        task?.sendPing { [weak self] error in
            if let error {
                print("❌ [WS] ping failed: \(error.localizedDescription)")
                self?.handleDisconnect()
            }
        }
    }

    // MARK: - App lifecycle

    @objc private func appDidEnterBackground() {
        stop()
    }

    @objc private func appWillEnterForeground() {
        startIfPossible()
    }

    // MARK: - Receive

    private func receiveLoop() {
        guard let task else { return }
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.retryCount = 0
                switch message {
                case .string(let text):
                    self.handle(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handle(text)
                    }
                @unknown default:
                    break
                }
                self.receiveLoop()
            case .failure(let error):
                print("❌ [WS] receive failed: \(error.localizedDescription)")
                self.handleDisconnect()
            }
        }
    }

    private func handleDisconnect() {
        guard isStarted else { return }
        isStarted = false
        stopPing()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        let delay = min(2 * pow(2, Double(retryCount)), Self.maxRetryDelay)
        retryCount += 1
        print("🔄 [WS] reconnect in \(Int(delay))s (attempt \(retryCount))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !self.isStarted else { return }
            guard APIConfig.isConfigured else { return }

            // Only refresh token after multiple failed attempts (likely token expired)
            let shouldRefreshToken = self.retryCount > 2

            Task {
                if shouldRefreshToken {
                    do {
                        let response = try await AuthService.shared.refresh()
                        let newToken = (response.accessToken ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !newToken.isEmpty {
                            APIClient.shared.accessToken = newToken
                            print("✅ [WS] token refreshed")
                        }
                    } catch {
                        print("⚠️ [WS] token refresh failed: \(error.localizedDescription)")
                    }
                }

                await MainActor.run {
                    guard !self.isStarted else { return }
                    if let token = APIClient.shared.accessToken, !token.isEmpty {
                        self.connect(token: token)
                    }
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = object["event"] as? String,
              event == "inbox_message",
              let payload = object["data"] as? [String: Any],
              let title = payload["title"] as? String,
              let body = payload["body"] as? String else {
            return
        }

        let remoteID = payload["id"] as? String
        let kind: PushInboxKind = ((payload["type"] as? String) ?? "").lowercased() == "system" ? .system : .other
        let message = PushInboxMessage(
            title: title,
            body: body,
            kind: kind,
            remoteID: remoteID,
            rawPayloadJSON: text,
            createdAt: InboxDateParser.parse(payload["createdAt"] as? String) ?? Date(),
            isUnread: !((payload["read"] as? Bool) ?? false)
        )
        Task {
            await PushInboxStore.shared.append(message)
        }
    }

    private func makeWebSocketURL(baseURL: URL, accessToken: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        components.scheme = (components.scheme == "https") ? "wss" : "ws"
        components.path = "/ws"
        components.queryItems = [
            URLQueryItem(name: "accessToken", value: accessToken),
            URLQueryItem(name: "bundleId", value: Bundle.main.bundleIdentifier ?? "")
        ]
        return components.url ?? baseURL
    }
}
