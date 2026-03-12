import Foundation

enum PushInboxKind: String, Codable {
    case system
    case other
}

struct PushInboxMessage: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let kind: PushInboxKind
    let remoteID: String?
    let rawPayloadJSON: String?
    let createdAt: Date
    var isUnread: Bool

    nonisolated init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        kind: PushInboxKind,
        remoteID: String?,
        rawPayloadJSON: String?,
        createdAt: Date = Date(),
        isUnread: Bool = true
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.kind = kind
        self.remoteID = remoteID
        self.rawPayloadJSON = rawPayloadJSON
        self.createdAt = createdAt
        self.isUnread = isUnread
    }
}

extension Notification.Name {
    nonisolated static let pushInboxDidUpdate = Notification.Name("dailyspeak.pushInboxDidUpdate")
}

actor PushInboxStore {
    static let shared = PushInboxStore()

    private let defaults = UserDefaults.standard
    private let storageKey = "dailyspeak.pushInbox.messages"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func load() -> [PushInboxMessage] {
        guard let data = defaults.data(forKey: storageKey),
              let messages = try? decoder.decode([PushInboxMessage].self, from: data) else {
            return []
        }
        let merged = mergeDuplicates(in: messages)
        persistIfNeeded(merged, original: messages)
        return merged
    }

    func unreadCount() -> Int {
        load().filter(\.isUnread).count
    }

    func append(_ message: PushInboxMessage) {
        append(contentsOf: [message])
    }

    func append(contentsOf messages: [PushInboxMessage]) {
        guard !messages.isEmpty else { return }
        let merged = mergeDuplicates(in: load() + messages)
        persist(merged)
    }

    func markRead(id: String) {
        var current = load()
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].isUnread = false
            persist(current)
        }
    }

    func markAllRead() {
        let current = load().map { message in
            PushInboxMessage(
                id: message.id,
                title: message.title,
                body: message.body,
                kind: message.kind,
                remoteID: message.remoteID,
                rawPayloadJSON: message.rawPayloadJSON,
                createdAt: message.createdAt,
                isUnread: false
            )
        }
        persist(current)
    }

    private func persist(_ messages: [PushInboxMessage]) {
        if let data = try? encoder.encode(messages.sorted { $0.createdAt > $1.createdAt }) {
            defaults.set(data, forKey: storageKey)
        }
        NotificationCenter.default.post(name: .pushInboxDidUpdate, object: nil)
    }

    private func persistIfNeeded(_ merged: [PushInboxMessage], original: [PushInboxMessage]) {
        guard merged != original else { return }
        if let data = try? encoder.encode(merged.sorted { $0.createdAt > $1.createdAt }) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func mergeDuplicates(in messages: [PushInboxMessage]) -> [PushInboxMessage] {
        var merged: [PushInboxMessage] = []
        for message in messages.sorted(by: { $0.createdAt > $1.createdAt }) {
            if let index = merged.firstIndex(where: { isSameMessage($0, message) }) {
                merged[index] = merge(merged[index], with: message)
            } else {
                merged.append(message)
            }
        }
        return merged.sorted { $0.createdAt > $1.createdAt }
    }

    private func isSameMessage(_ lhs: PushInboxMessage, _ rhs: PushInboxMessage) -> Bool {
        let leftRemoteID = normalizedRemoteID(lhs.remoteID)
        let rightRemoteID = normalizedRemoteID(rhs.remoteID)
        if let leftRemoteID, let rightRemoteID {
            return leftRemoteID == rightRemoteID
        }

        let closeEnough = abs(lhs.createdAt.timeIntervalSince(rhs.createdAt)) <= 600
        return closeEnough && fallbackSignature(for: lhs) == fallbackSignature(for: rhs)
    }

    private func merge(_ lhs: PushInboxMessage, with rhs: PushInboxMessage) -> PushInboxMessage {
        PushInboxMessage(
            id: lhs.id,
            title: rhs.title.count > lhs.title.count ? rhs.title : lhs.title,
            body: rhs.body.count > lhs.body.count ? rhs.body : lhs.body,
            kind: lhs.kind,
            remoteID: normalizedRemoteID(lhs.remoteID) ?? normalizedRemoteID(rhs.remoteID),
            rawPayloadJSON: lhs.rawPayloadJSON ?? rhs.rawPayloadJSON,
            createdAt: min(lhs.createdAt, rhs.createdAt),
            isUnread: lhs.isUnread && rhs.isUnread
        )
    }

    private func normalizedRemoteID(_ remoteID: String?) -> String? {
        guard let remoteID else { return nil }
        let value = remoteID.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func fallbackSignature(for message: PushInboxMessage) -> String {
        [
            message.kind.rawValue,
            message.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            message.body.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        ].joined(separator: "||")
    }
}
