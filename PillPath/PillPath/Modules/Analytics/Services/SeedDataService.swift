
import Foundation
import CoreData

final class SeedDataService {

    private let coreData: CoreDataStack
    private let scheduleService: ScheduleServiceProtocol

    init(
        coreData: CoreDataStack = .shared,
        scheduleService: ScheduleServiceProtocol? = nil
    ) {
        self.coreData = coreData
        self.scheduleService = scheduleService ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
    }

    @discardableResult
    func seedDemoHistory(days: Int = 30) throws -> Int {
        let context = coreData.viewContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let fromDate = calendar.date(byAdding: .day, value: -days, to: today) else { return 0 }

        let schedules = try scheduleService.fetchAll().filter(\.isActive)
        guard !schedules.isEmpty else { return 0 }

        var created = 0

        for schedule in schedules {
            let schedReq = ScheduleEntity.fetchRequest()
            schedReq.predicate = NSPredicate(format: "id == %@", schedule.id as CVarArg)
            schedReq.fetchLimit = 1
            guard let schedEntity = try context.fetch(schedReq).first,
                  let medEntity = schedEntity.medication else { continue }

            let doseTimes = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: days, from: fromDate)
                .filter { $0 >= fromDate && $0 < today }

            for doseTime in doseTimes {
                let check = DoseLogEntity.fetchRequest()
                check.predicate = NSPredicate(
                    format: "schedule == %@ AND scheduledAt >= %@ AND scheduledAt < %@",
                    schedEntity,
                    doseTime.addingTimeInterval(-30) as CVarArg,
                    doseTime.addingTimeInterval(30) as CVarArg
                )
                check.fetchLimit = 1
                if let existing = try? context.fetch(check), !existing.isEmpty { continue }

                let rand = Int.random(in: 1...100)
                let (status, takenAt): (String, Date?)
                switch rand {
                case 1...85:
                    status = "taken"
                    takenAt = doseTime.addingTimeInterval(Double.random(in: 60...1200))
                case 86...95:
                    status = "missed"
                    takenAt = nil
                default:
                    status = "skipped"
                    takenAt = nil
                }

                let log = DoseLogEntity(context: context)
                log.id = UUID()
                log.scheduledAt = doseTime
                log.status = status
                log.takenAt = takenAt
                log.schedule = schedEntity
                log.medication = medEntity
                created += 1
            }
        }

        if created > 0 { coreData.save() }
        return created
    }
}
