//
//  DoseTrackingService.swift
//  PillPath — Scheduling Module
//

import Foundation
import CoreData

protocol DoseTrackingServiceProtocol {
    // Distinct external labels so the two UUID overloads don't collide
    func fetchLogs(medicationId: UUID) throws -> [DoseLog]
    func fetchLogs(scheduleId: UUID) throws -> [DoseLog]
    func fetchLogs(on date: Date) throws -> [DoseLog]
    func fetchLogs(from startDate: Date, to endDate: Date) throws -> [DoseLog]
    func markTaken(_ log: DoseLog, at time: Date) throws
    func markPending(_ log: DoseLog) throws
    func markSkipped(_ log: DoseLog) throws
    func detectAndMarkMissed() throws
    func generateUpcomingLogs(for schedule: MedicationSchedule, days: Int) throws
}

final class DoseTrackingService: DoseTrackingServiceProtocol {

    private let coreData: CoreDataStack

    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
    }

    // MARK: - Fetch

    func fetchLogs(medicationId: UUID) throws -> [DoseLog] {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "medication.id == %@", medicationId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: false)]
        return try coreData.viewContext.fetch(request).compactMap { DoseLogMapper.toDomain($0) }
    }

    func fetchLogs(scheduleId: UUID) throws -> [DoseLog] {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "schedule.id == %@", scheduleId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try coreData.viewContext.fetch(request).compactMap { DoseLogMapper.toDomain($0) }
    }

    func fetchLogs(on date: Date) throws -> [DoseLog] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end   = calendar.date(byAdding: .day, value: 1, to: start)!
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "scheduledAt >= %@ AND scheduledAt < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try coreData.viewContext.fetch(request).compactMap { DoseLogMapper.toDomain($0) }
    }

    func fetchLogs(from startDate: Date, to endDate: Date) throws -> [DoseLog] {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "scheduledAt >= %@ AND scheduledAt < %@",
            startDate as CVarArg, endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        return try coreData.viewContext.fetch(request).compactMap { DoseLogMapper.toDomain($0) }
    }

    // MARK: - Mark Status
    // Inline the update logic directly — avoids Swift 6 typed-throws inference
    // issues that arise when passing a non-throwing closure to a `throws` function.

    func markTaken(_ log: DoseLog, at time: Date = .now) throws {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", log.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        entity.status  = DoseStatus.taken.rawValue
        entity.takenAt = time
        coreData.save()
    }

    func markPending(_ log: DoseLog) throws {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", log.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        entity.status  = DoseStatus.pending.rawValue
        entity.takenAt = nil
        coreData.save()
    }

    func markSkipped(_ log: DoseLog) throws {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", log.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        entity.status = DoseStatus.skipped.rawValue
        coreData.save()
    }

    // MARK: - Missed Dose Detection

    func detectAndMarkMissed() throws {
        let request = DoseLogEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "status == %@ AND scheduledAt < %@",
            DoseStatus.pending.rawValue, Date.now as CVarArg
        )
        let entities = try coreData.viewContext.fetch(request)
        entities.forEach { $0.status = DoseStatus.missed.rawValue }
        coreData.save()
    }

    // MARK: - Generate Upcoming Logs

    func generateUpcomingLogs(for schedule: MedicationSchedule, days: Int = 7) throws {
        let upcoming = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: days)

        let schedRequest = ScheduleEntity.fetchRequest()
        schedRequest.predicate = NSPredicate(format: "id == %@", schedule.id as CVarArg)
        schedRequest.fetchLimit = 1
        guard let scheduleEntity = try coreData.viewContext.fetch(schedRequest).first else { return }
        guard let medicationEntity = scheduleEntity.medication else { return }

        for doseTime in upcoming {
            // Skip duplicates using a separate do-catch — avoids Swift 6 try? inference issue
            let check = DoseLogEntity.fetchRequest()
            check.predicate = NSPredicate(
                format: "schedule.id == %@ AND scheduledAt == %@",
                schedule.id as CVarArg, doseTime as CVarArg
            )
            check.fetchLimit = 1
            let alreadyExists: Bool
            do {
                let results = try coreData.viewContext.fetch(check)
                alreadyExists = !results.isEmpty
            } catch {
                alreadyExists = false
            }
            guard !alreadyExists else { continue }

            let entity        = DoseLogEntity(context: coreData.viewContext)
            entity.id         = UUID()
            entity.scheduledAt = doseTime
            entity.status     = DoseStatus.pending.rawValue
            entity.schedule   = scheduleEntity
            entity.medication = medicationEntity
        }
        coreData.save()
    }
}
