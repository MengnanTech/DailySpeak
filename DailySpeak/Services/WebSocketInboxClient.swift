import Foundation

final class WebSocketInboxClient {
    static let shared = WebSocketInboxClient()

    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var isStarted = false

    private init() {}

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

        let url = makeWebSocketURL(baseURL: APIConfig.baseURL, accessToken: token)
        print("⬆️ [WS CONNECT] \(url.absoluteString)")

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
    }

    func stop() {
        isStarted = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    private func receiveLoop() {
        guard let task else { return }
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
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
            case .failure:
                print("❌ [WS] receive failed")
                self.isStarted = false
                self.task = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startIfPossible()
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
        let message = PushInboxMessage(title: title, body: body, kind: kind, remoteID: remoteID, rawPayloadJSON: text)
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
