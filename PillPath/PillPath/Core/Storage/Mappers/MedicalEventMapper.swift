//
//  MedicalEventMapper.swift
//  PillPath
//
//  All extra fields (provider, description, medicationIds) are packed
//  into eventDescription as JSON: {"p":"","d":"","m":["uuid1","uuid2"]}
//  Plain strings (legacy data) are treated as description-only.
//

import Foundation
import CoreData

enum MedicalEventMapper {

    // MARK: - toDomain

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
            createdAt: createdAt
        )
    }

    // MARK: - toEntity

    static func toEntity(_ event: MedicalEvent, context: NSManagedObjectContext) -> MedicalEventEntity {
        let entity = fetchOrCreate(id: event.id, context: context)
        entity.id               = event.id
        entity.title            = event.title
        entity.eventDescription = pack(provider: event.provider,
                                       description: event.notes,
                                       medicationIds: event.medicationIds)
        entity.date             = event.date
        entity.type             = event.type.rawValue
        entity.createdAt        = event.createdAt
        return entity
    }

    // MARK: - Packing helpers

    private struct Payload: Codable {
        var p: String   // provider
        var d: String   // description
        var m: [String] // medicationId UUIDs
    }

    private static func pack(provider: String?, description: String?, medicationIds: [UUID]) -> String? {
        let payload = Payload(
            p: provider    ?? "",
            d: description ?? "",
            m: medicationIds.map(\.uuidString)
        )
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func unpack(_ stored: String?) -> (provider: String?, description: String?, medicationIds: [UUID]) {
        guard let stored, !stored.isEmpty else { return (nil, nil, []) }
        if let data = stored.data(using: .utf8),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            let provider      = payload.p.isEmpty ? nil : payload.p
            let description   = payload.d.isEmpty ? nil : payload.d
            let medicationIds = payload.m.compactMap { UUID(uuidString: $0) }
            return (provider, description, medicationIds)
        }
        // Legacy: treat as plain description string
        return (nil, stored, [])
    }

    private static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> MedicalEventEntity {
        let request = MedicalEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) ?? MedicalEventEntity(context: context)
    }
}
