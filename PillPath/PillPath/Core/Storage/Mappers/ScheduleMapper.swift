//
//  ScheduleMapper.swift
//  PillPath
//

import Foundation
import CoreData

enum ScheduleMapper {

    // MARK: - Entity → Domain

    static func toDomain(_ entity: ScheduleEntity) -> MedicationSchedule? {
        guard let id = entity.id,
              let medicationId = entity.medication?.id,
              let startDate = entity.startDate else { return nil }

        let times = (entity.scheduleTimes as? Set<ScheduleTimeEntity>)?
            .compactMap { ScheduleTimeMapper.toDomain($0) }
            .sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
            ?? []

        let specificDays = entity.specificDaysJSON
            .flatMap { JSONHelper.decodeIntArray($0) } ?? []

        return MedicationSchedule(
            id: id,
            medicationId: medicationId,
            frequency: ScheduleFrequency(rawValue: entity.frequency ?? "daily") ?? .daily,
            intervalHours: Int(entity.intervalHours),
            specificDays: specificDays,
            scheduleTimes: times,
            mealTiming: MealTiming(rawValue: entity.mealTiming ?? "none") ?? .none,
            startDate: startDate,
            endDate: entity.endDate,
            isOngoing: entity.isOngoing,
            doseReminders: entity.doseReminders,
            notificationOffsetMinutes: NotificationOffset(rawValue: Int(entity.notificationOffsetMinutes)) ?? .atTime,
            isActive: entity.isActive
        )
    }

    // MARK: - Domain → Entity (upsert)

    static func toEntity(_ schedule: MedicationSchedule, context: NSManagedObjectContext) -> ScheduleEntity {
        let entity = fetchOrCreate(id: schedule.id, context: context)
        entity.id              = schedule.id
        entity.frequency       = schedule.frequency.rawValue
        entity.intervalHours   = Int32(schedule.intervalHours)
        entity.specificDaysJSON = JSONHelper.encodeIntArray(schedule.specificDays)
        entity.mealTiming      = schedule.mealTiming.rawValue
        entity.startDate       = schedule.startDate
        entity.endDate         = schedule.endDate
        entity.isOngoing       = schedule.isOngoing
        entity.doseReminders   = schedule.doseReminders
        entity.notificationOffsetMinutes = Int32(schedule.notificationOffsetMinutes.rawValue)
        entity.isActive        = schedule.isActive

        // Rebuild schedule times
        if let existing = entity.scheduleTimes as? Set<ScheduleTimeEntity> {
            existing.forEach { context.delete($0) }
        }
        let timeEntities = schedule.scheduleTimes.map { time -> ScheduleTimeEntity in
            let t = ScheduleTimeEntity(context: context)
            t.id     = time.id
            t.hour   = Int32(time.hour)
            t.minute = Int32(time.minute)
            t.label  = time.label.rawValue
            return t
        }
        entity.scheduleTimes = NSSet(array: timeEntities)
        return entity
    }

    private static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> ScheduleEntity {
        let request = ScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) ?? ScheduleEntity(context: context)
    }
}

// MARK: - ScheduleTime helper

enum ScheduleTimeMapper {
    static func toDomain(_ entity: ScheduleTimeEntity) -> ScheduleTime? {
        guard let id = entity.id else { return nil }
        return ScheduleTime(
            id: id,
            hour: Int(entity.hour),
            minute: Int(entity.minute),
            label: DoseTimeLabel(rawValue: entity.label ?? "custom") ?? .custom
        )
    }
}
