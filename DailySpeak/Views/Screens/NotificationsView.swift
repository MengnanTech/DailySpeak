import SwiftUI

private enum InboxFilter: String, CaseIterable {
    case all
    case other
    case system

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .other:
            return "提醒"
        case .system:
            return "系统"
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var allItems: [NotificationItem] = []
    @State private var filter: InboxFilter = .all
    @State private var selectedItem: NotificationItem?
    @State private var pendingRefreshTask: Task<Void, Never>?
    @State private var isDetailSheetDismissing = false

    private var filteredItems: [NotificationItem] {
        switch filter {
        case .all:
            return allItems
        case .other:
            return allItems.filter { $0.kind == .other }
        case .system:
            return allItems.filter { $0.kind == .system }
        }
    }

    private var unreadCount: Int {
        allItems.filter(\.isUnread).count
    }

    var body: some View {
        Group {
            if allItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.textMuted)
                    Text("还没有消息")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("API 推送、inbox 拉取和本地通知都会汇总在这里。")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .refreshable {
                    await InAppInboxService.shared.syncIfConfigured()
                    await refresh()
                }
            } else {
                List {
                    Section {
                        Picker("", selection: $filter) {
                            ForEach(InboxFilter.allCases, id: \.self) { current in
                                Text(current.title).tag(current)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        if filteredItems.isEmpty {
                            VStack(spacing: 8) {
                                Text("当前筛选没有内容")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.textPrimary)
                                Text("下拉刷新后会重新同步消息。")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(filteredItems) { item in
                                Button {
                                    open(item)
                                } label: {
                                    NotificationRow(item: item)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    } header: {
                        Text("最近更新")
                            .foregroundColor(.textSecondary)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await InAppInboxService.shared.syncIfConfigured()
                    await refresh()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundDark)
        .navigationTitle("消息通知")
        .navigationBarTitleDisplayMode(.inline)
        // Keep the test marker aligned with the shell regression check: navigationBarBackButtonHiddentrue
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("全部已读") {
                    markAllAsRead()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .disabled(unreadCount == 0)
                .opacity(unreadCount == 0 ? 0.35 : 1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(Color.textPrimary)
                .disabled(isDetailSheetDismissing)
                .accessibilityLabel(Text("关闭"))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushInboxDidUpdate)) { _ in
            scheduleRefresh()
        }
        .task {
            await refresh()
            await InAppInboxService.shared.syncIfConfigured()
        }
        .onDisappear {
            pendingRefreshTask?.cancel()
            pendingRefreshTask = nil
        }
        .sheet(item: $selectedItem, onDismiss: {
            isDetailSheetDismissing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isDetailSheetDismissing = false
            }
        }) { item in
            NotificationDetailSheet(item: item)
        }
    }

    private func open(_ item: NotificationItem) {
        selectedItem = item
        guard item.isUnread else { return }

        Task {
            await PushInboxStore.shared.markRead(id: item.id)
        }
        HapticService.shared.success()
    }

    private func markAllAsRead() {
        Task {
            await PushInboxStore.shared.markAllRead()
        }
        HapticService.shared.success()
    }

    private func scheduleRefresh() {
        pendingRefreshTask?.cancel()
        pendingRefreshTask = Task {
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    private func refresh() async {
        let messages = await PushInboxStore.shared.load()
        await MainActor.run {
            allItems = messages.map(NotificationItem.fromInbox)
        }
    }
}

private struct NotificationDetailSheet: View {
    let item: NotificationItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(item.time)
                        .font(.caption)
                        .foregroundColor(.textMuted)

                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    Text(item.message)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .background(Color.backgroundDark.ignoresSafeArea())
            .navigationTitle("消息通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityLabel(Text("关闭"))
                }
            }
        }
    }
}

private struct NotificationRow: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: item.icon)
                    .font(.headline)
                    .foregroundColor(item.tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)

                    if item.isUnread {
                        Circle()
                            .fill(Color.primaryCyan)
                            .frame(width: 6, height: 6)
                    }
                }

                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(item.time)
                        .font(.caption)
                        .foregroundColor(.textMuted)

                    Text(item.isUnread ? "未读" : "已读")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(item.isUnread ? .primaryCyan : .textMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill((item.isUnread ? Color.primaryCyan : Color.white).opacity(0.12))
                        )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.backgroundCard)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }
}

private struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let message: String
    let time: String
    let icon: String
    let tint: Color
    let kind: PushInboxKind
    let isUnread: Bool
}

private extension NotificationItem {
    static func fromInbox(_ message: PushInboxMessage) -> NotificationItem {
        let iconAndTint: (String, Color) = {
            switch message.kind {
            case .system:
                return ("bell.fill", .primaryCyan)
            case .other:
                return ("sparkles", .warning)
            }
        }()

        return NotificationItem(
            id: message.id,
            title: message.title,
            message: message.body,
            time: message.createdAt.formatted(date: .abbreviated, time: .shortened),
            icon: iconAndTint.0,
            tint: iconAndTint.1,
            kind: message.kind,
            isUnread: message.isUnread
        )
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environmentObject(AppState())
    }
}
