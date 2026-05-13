
import Foundation
import CoreData

extension NotificationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationEntity> {
        NSFetchRequest<NotificationEntity>(entityName: "NotificationEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var title: String?
    @NSManaged public var body: String?
    @NSManaged public var type: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var deepLinkTarget: String?
}

extension NotificationEntity: Identifiable {}
