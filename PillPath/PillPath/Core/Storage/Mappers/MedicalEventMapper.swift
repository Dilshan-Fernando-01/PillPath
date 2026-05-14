
import Foundation
import CoreData

enum MedicalEventMapper {

  

    static func toDomain(_ entity: MedicalEventEntity) -> MedicalEvent? {
        guard let id        = entity.id,
              let title     = entity.title,
              let date      = entity.date,
              let createdAt = entity.createdAt else { return nil }

        let payload = unpack(entity.eventDescription)
        return MedicalEvent(
            id: id,
            title: title,
            notes: payload.description,
            provider: payload.provider,
            medicationIds: payload.medicationIds,
            date: date,
            type: MedicalEventType(rawValue: entity.type ?? "note") ?? .note,
            attachmentFilename: payload.attachmentFilename,
            attachmentDisplayName: payload.attachmentDisplayName,
            createdAt: createdAt
        )
    }

    static func toEntity(_ event: MedicalEvent, context: NSManagedObjectContext) -> MedicalEventEntity {
        let entity = fetchOrCreate(id: event.id, context: context)
        entity.id               = event.id
        entity.userId           = AppSession.shared.currentUserId.isEmpty ? nil : AppSession.shared.currentUserId
        entity.title            = event.title
        entity.eventDescription = pack(provider: event.provider,
                                       description: event.notes,
                                       medicationIds: event.medicationIds,
                                       attachmentFilename: event.attachmentFilename,
                                       attachmentDisplayName: event.attachmentDisplayName)
        entity.date             = event.date
        entity.type             = event.type.rawValue
        entity.createdAt        = event.createdAt
        return entity
    }

    private struct Payload: Codable {
        var p: String
        var d: String
        var m: [String]
        var a: String?
        var an: String?
    }

    private static func pack(provider: String?, description: String?, medicationIds: [UUID],
                             attachmentFilename: String?, attachmentDisplayName: String?) -> String? {
        let payload = Payload(
            p: provider    ?? "",
            d: description ?? "",
            m: medicationIds.map(\.uuidString),
            a: attachmentFilename,
            an: attachmentDisplayName
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func unpack(_ stored: String?) -> (provider: String?, description: String?, medicationIds: [UUID], attachmentFilename: String?, attachmentDisplayName: String?) {
        guard let stored, !stored.isEmpty else { return (nil, nil, [], nil, nil) }
        if let data = stored.data(using: .utf8),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            let provider      = payload.p.isEmpty ? nil : payload.p
            let description   = payload.d.isEmpty ? nil : payload.d
            let medicationIds = payload.m.compactMap { UUID(uuidString: $0) }
            return (provider, description, medicationIds, payload.a, payload.an)
        }
        return (nil, stored, [], nil, nil)
    }

    private static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> MedicalEventEntity {
        let request = MedicalEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) ?? MedicalEventEntity(context: context)
    }
}
