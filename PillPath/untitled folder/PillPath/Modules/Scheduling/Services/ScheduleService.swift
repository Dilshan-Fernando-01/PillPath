

import Foundation
import CoreData

protocol ScheduleServiceProtocol {
    func fetchAll() throws -> [MedicationSchedule]
    func fetch(for medicationId: UUID) throws -> [MedicationSchedule]
    func save(_ schedule: MedicationSchedule, for medication: Medication) throws
    func delete(_ schedule: MedicationSchedule) throws
    func setActive(_ isActive: Bool, scheduleId: UUID) throws
}

final class ScheduleService: ScheduleServiceProtocol {

    private let coreData: CoreDataStack
    private let notificationService: NotificationServiceProtocol

    init(coreData: CoreDataStack = .shared, notificationService: NotificationServiceProtocol = NotificationService()) {
        self.coreData = coreData
        self.notificationService = notificationService
    }

    

    func fetchAll() throws -> [MedicationSchedule] {
        let request = ScheduleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { ScheduleMapper.toDomain($0) }
    }

    func fetch(for medicationId: UUID) throws -> [MedicationSchedule] {
        let request = ScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "medication.id == %@", medicationId as CVarArg)
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { ScheduleMapper.toDomain($0) }
    }


    func save(_ schedule: MedicationSchedule, for medication: Medication) throws {
       
        let medRequest = MedicationEntity.fetchRequest()
        medRequest.predicate = NSPredicate(format: "id == %@", medication.id as CVarArg)
        medRequest.fetchLimit = 1
        guard let medicationEntity = try coreData.viewContext.fetch(medRequest).first else {
            throw ScheduleError.medicationNotFound
        }

        let entity = ScheduleMapper.toEntity(schedule, context: coreData.viewContext)
        entity.medication = medicationEntity
        coreData.save()

      
        if schedule.doseReminders {
            notificationService.scheduleNotifications(for: schedule, medication: medication)
        }
    }

   

    func delete(_ schedule: MedicationSchedule) throws {
        let request = ScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", schedule.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        notificationService.cancelNotifications(for: schedule.id)
        coreData.viewContext.delete(entity)
        coreData.save()
    }

    func setActive(_ isActive: Bool, scheduleId: UUID) throws {
        let request = ScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", scheduleId as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        entity.isActive = isActive
        coreData.save()
    }
}

enum ScheduleError: LocalizedError {
    case medicationNotFound

    var errorDescription: String? {
        switch self {
        case .medicationNotFound: return "Medication not found. Save the medication before adding a schedule."
        }
    }
}
