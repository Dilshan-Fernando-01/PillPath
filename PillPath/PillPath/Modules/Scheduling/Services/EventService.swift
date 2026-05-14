
import Foundation
import CoreData

protocol EventServiceProtocol {
    func fetchAll() throws -> [MedicalEvent]
    func save(_ event: MedicalEvent) throws
    func delete(_ event: MedicalEvent) throws
}

final class EventService: EventServiceProtocol {

    private let coreData: CoreDataStack
    private let notificationService: NotificationServiceProtocol
    private let inAppService: InAppNotificationServiceProtocol

    init(coreData: CoreDataStack = .shared,
         notificationService: NotificationServiceProtocol = DIContainer.shared.resolve(NotificationServiceProtocol.self),
         inAppService: InAppNotificationServiceProtocol = DIContainer.shared.resolve(InAppNotificationServiceProtocol.self)) {
        self.coreData = coreData
        self.notificationService = notificationService
        self.inAppService = inAppService
    }

    func fetchAll() throws -> [MedicalEvent] {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return [] }
        let request = MedicalEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", uid)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { MedicalEventMapper.toDomain($0) }
    }

    func save(_ event: MedicalEvent) throws {
        _ = MedicalEventMapper.toEntity(event, context: coreData.viewContext)
        coreData.save()

        notificationService.scheduleEventReminder(for: event)

        let hoursUntil = event.date.timeIntervalSinceNow / 3600
        if hoursUntil > 0 && hoursUntil <= 24 {
            let deepLink = "event_\(event.id.uuidString)"
            try? inAppService.create(
                type: .eventReminder,
                title: "Upcoming: \(event.title)",
                body: "Your \(event.type.displayName) is scheduled for \(event.date.formatted(.dateTime.day().month().hour().minute())).",
                deepLink: deepLink
            )
        }
    }

    func delete(_ event: MedicalEvent) throws {
        notificationService.cancelEventReminder(for: event.id)
        DocumentStorage.delete(event.attachmentFilename)
        let request = MedicalEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        coreData.viewContext.delete(entity)
        coreData.save()
    }
}
