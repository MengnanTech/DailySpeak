import Foundation

private struct InAppInboxMessageDTO: Decodable {
    let id: String
    let title: String
    let body: String
    let type: String?
}

final class InAppInboxService {
    static let shared = InAppInboxService()

    private init() {}

    func syncIfConfigured() async {
        guard APIConfig.isConfigured else { return }
        do {
            let response: APIEnvelope<[InAppInboxMessageDTO]> = try await APIClient.shared.request(
                "inbox",
                queryItems: [URLQueryItem(name: "bundleId", value: Bundle.main.bundleIdentifier ?? "")],
                requiresAuth: true
            )
            guard response.code == 200 else { return }
            let messages = (response.data ?? []).map { item in
                PushInboxMessage(
                    title: item.title,
                    body: item.body,
                    kind: ((item.type ?? "").lowercased() == "system") ? .system : .other,
                    remoteID: item.id,
                    rawPayloadJSON: nil
                )
            }
            await PushInboxStore.shared.append(contentsOf: messages)
        } catch {
            return
        }
    }
}
