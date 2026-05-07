//
//  DoseLogMapper.swift
//  PillPath
//

import Foundation
import CoreData

enum DoseLogMapper {

    static func toDomain(_ entity: DoseLogEntity) -> DoseLog? {
        guard let id = entity.id,
              let medicationId = entity.medication?.id,
              let scheduleId = entity.schedule?.id,
              let scheduledAt = entity.scheduledAt else { return nil }

        return DoseLog(
            id: id,
            medicationId: medicationId,
            scheduleId: scheduleId,
            scheduledAt: scheduledAt,
            takenAt: entity.takenAt,
            status: DoseStatus(rawValue: entity.status ?? "pending") ?? .pending,
            notes: entity.notes
        )
    }

    static func toEntity(_ log: DoseLog, context: NSManagedObjectContext) -> DoseLogEntity {
        let entity = fetchOrCreate(id: log.id, context: context)
        entity.id          = log.id
        entity.scheduledAt = log.scheduledAt
        entity.takenAt     = log.takenAt
        entity.status      = log.status.rawValue
        entity.notes       = log.notes
        return entity
    }

    private static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> DoseLogEntity {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) ?? DoseLogEntity(context: context)
    }
}
