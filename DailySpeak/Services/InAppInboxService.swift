import Foundation

private struct InAppInboxMessageDTO: Decodable {
    let id: String
    let title: String
    let body: String
    let type: String?
    let read: Bool?
    let createdAt: String?
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
                    rawPayloadJSON: nil,
                    createdAt: InboxDateParser.parse(item.createdAt) ?? Date(),
                    isUnread: !(item.read ?? false)
                )
            }
            await PushInboxStore.shared.append(contentsOf: messages)
        } catch {
            return
        }
    }
}

enum InboxDateParser {
    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let localDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return iso8601WithFractional.date(from: value)
            ?? iso8601.date(from: value)
            ?? localDateTimeFormatter.date(from: value)
    }
}
