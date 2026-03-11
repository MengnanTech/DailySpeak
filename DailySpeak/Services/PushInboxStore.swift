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
        return messages.sorted { $0.createdAt > $1.createdAt }
    }

    func unreadCount() -> Int {
        load().filter(\.isUnread).count
    }

    func append(_ message: PushInboxMessage) {
        append(contentsOf: [message])
    }

    func append(contentsOf messages: [PushInboxMessage]) {
        guard !messages.isEmpty else { return }
        var current = load()
        for message in messages {
            if let remoteID = message.remoteID, current.contains(where: { $0.remoteID == remoteID }) {
                continue
            }
            current.append(message)
        }
        persist(current)
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
}
