
import Foundation
import Combine

@MainActor
final class NotificationBellViewModel: ObservableObject {

    @Published var notifications: [InAppNotification] = []
    @Published var showInbox = false

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    var hasUnread: Bool   { unreadCount > 0 }

    private let service: InAppNotificationServiceProtocol

    init(service: InAppNotificationServiceProtocol = DIContainer.shared.resolve(InAppNotificationServiceProtocol.self)) {
        self.service = service
        load()
        NotificationCenter.default.addObserver(
            forName: .inAppNotificationAdded, object: nil, queue: .main
        ) { [weak self] _ in self?.load() }
    }

    func load() {
        notifications = (try? service.fetchAll()) ?? []
    }

    func markRead(_ id: UUID) {
        try? service.markRead(id)
        load()
    }

    func markAllRead() {
        try? service.markAllRead()
        load()
    }

    func delete(_ id: UUID) {
        try? service.delete(id)
        load()
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach { i in
            guard i < notifications.count else { return }
            delete(notifications[i].id)
        }
    }
}
