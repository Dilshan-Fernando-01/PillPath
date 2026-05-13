
import Foundation
import CoreData

protocol InAppNotificationServiceProtocol {
    func create(type: InAppNotificationType, title: String, body: String, deepLink: String?) throws
    func fetchAll() throws -> [InAppNotification]
    func unreadCount() throws -> Int
    func markRead(_ id: UUID) throws
    func markAllRead() throws
    func delete(_ id: UUID) throws
    func hasNotification(deepLink: String) -> Bool
}

final class InAppNotificationService: InAppNotificationServiceProtocol {

    private let coreData: CoreDataStack

    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
    }

    func create(type: InAppNotificationType, title: String, body: String, deepLink: String?) throws {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return }
        if let deepLink, hasNotification(deepLink: deepLink) { return }

        let entity           = NotificationEntity(context: coreData.viewContext)
        entity.id            = UUID()
        entity.userId        = uid
        entity.title         = title
        entity.body          = body
        entity.type          = type.rawValue
        entity.isRead        = false
        entity.createdAt     = .now
        entity.deepLinkTarget = deepLink
        coreData.save()

        NotificationCenter.default.post(name: .inAppNotificationAdded, object: nil)
    }

    func fetchAll() throws -> [InAppNotification] {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return [] }
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "userId == %@", uid)
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try coreData.viewContext.fetch(req).compactMap(toDomain)
    }

    func unreadCount() throws -> Int {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return 0 }
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "userId == %@ AND isRead == NO", uid)
        return (try? coreData.viewContext.count(for: req)) ?? 0
    }

    func markRead(_ id: UUID) throws {
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(req).first else { return }
        entity.isRead = true
        coreData.save()
    }

    func markAllRead() throws {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return }
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "userId == %@ AND isRead == NO", uid)
        try coreData.viewContext.fetch(req).forEach { $0.isRead = true }
        coreData.save()
    }

    func delete(_ id: UUID) throws {
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(req).first else { return }
        coreData.viewContext.delete(entity)
        coreData.save()
    }

    func hasNotification(deepLink: String) -> Bool {
        let req = NotificationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "deepLinkTarget == %@", deepLink)
        req.fetchLimit = 1
        return ((try? coreData.viewContext.count(for: req)) ?? 0) > 0
    }

    private func toDomain(_ entity: NotificationEntity) -> InAppNotification? {
        guard let id        = entity.id,
              let userId    = entity.userId,
              let title     = entity.title,
              let body      = entity.body,
              let typeRaw   = entity.type,
              let type      = InAppNotificationType(rawValue: typeRaw),
              let createdAt = entity.createdAt else { return nil }
        return InAppNotification(id: id, userId: userId, title: title, body: body,
                                  type: type, isRead: entity.isRead,
                                  createdAt: createdAt, deepLinkTarget: entity.deepLinkTarget)
    }
}
