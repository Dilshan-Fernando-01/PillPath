
import XCTest
import CoreData
@testable import PillPath

final class HistoricalDataSeederTests: XCTestCase {

    private var stack: CoreDataStack!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: false)
    }

    override func tearDown() {
        stack = nil
        super.tearDown()
    }

    func test_seedHistoricalData() throws {
        let ctx = stack.viewContext
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let seeds: [(name: String, form: String, dosage: Double, unit: String, timesOfDay: [(Int, Int)])] = [
            ("Lisinopril", "tablet", 1, "pills", [(8, 0), (20, 0)]),
            ("Metformin",  "tablet", 2, "pills", [(7, 30), (13, 0), (19, 30)]),
            ("Vitamin D",  "capsule", 1, "pills", [(9, 0)])
        ]

        for seed in seeds {
            let medEntity = fetchOrCreateMedication(name: seed.name, form: seed.form,
                                                    dosage: seed.dosage, unit: seed.unit,
                                                    ctx: ctx)
            let schedEntity = fetchOrCreateSchedule(for: medEntity, ctx: ctx)

            for dayOffset in stride(from: -89, through: 0, by: 1) {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

                for (hour, minute) in seed.timesOfDay {
                    guard let doseTime = calendar.date(bySettingHour: hour, minute: minute,
                                                       second: 0, of: day) else { continue }
                    if doseTime > Date.now { continue }

                    let already = try fetchExistingLog(scheduleId: schedEntity.id!, doseTime: doseTime, ctx: ctx)
                    if already { continue }

                    let roll = Int.random(in: 0..<100)
                    let status: String
                    if roll < 82 { status = "taken" }
                    else if roll < 93 { status = "missed" }
                    else { status = "skipped" }

                    let log = DoseLogEntity(context: ctx)
                    log.id          = UUID()
                    log.scheduledAt = doseTime
                    log.status      = status
                    log.schedule    = schedEntity
                    log.medication  = medEntity
                    if status == "taken" {
                        let jitter = TimeInterval(Int.random(in: -300...600))
                        log.takenAt = doseTime.addingTimeInterval(jitter)
                    }
                }
            }
        }

        stack.save()
        let count = try ctx.count(for: DoseLogEntity.fetchRequest())
        XCTAssertGreaterThan(count, 0, "Historical data should have been seeded")
        print("Seeded historical logs — total in store: \(count)")
    }

  

    private func fetchOrCreateMedication(name: String, form: String, dosage: Double,
                                          unit: String, ctx: NSManagedObjectContext) -> MedicationEntity {
        let req = MedicationEntity.fetchRequest()
        req.predicate = NSPredicate(format: "name == %@", name)
        req.fetchLimit = 1
        if let existing = try? ctx.fetch(req).first { return existing }

        let med = MedicationEntity(context: ctx)
        med.id               = UUID()
        med.name             = name
        med.form             = form
        med.dosageAmount     = dosage
        med.dosageUnit       = unit
        med.isActive         = true
        med.addedAt          = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
        med.currentQuantity  = 30
        med.lowQuantityAlert = false
        med.lowQuantityThreshold = 5
        return med
    }

    private func fetchOrCreateSchedule(for med: MedicationEntity,
                                        ctx: NSManagedObjectContext) -> ScheduleEntity {
        let req = ScheduleEntity.fetchRequest()
        req.predicate = NSPredicate(format: "medication.id == %@", med.id! as CVarArg)
        req.fetchLimit = 1
        if let existing = try? ctx.fetch(req).first { return existing }

        let sched = ScheduleEntity(context: ctx)
        sched.id           = UUID()
        sched.frequency    = "daily"
        sched.intervalHours = 360
        sched.mealTiming   = "none"
        sched.startDate    = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
        sched.isOngoing    = true
        sched.doseReminders = false
        sched.isActive     = true
        sched.medication   = med
        return sched
    }

    private func fetchExistingLog(scheduleId: UUID, doseTime: Date,
                                   ctx: NSManagedObjectContext) throws -> Bool {
        let req = DoseLogEntity.fetchRequest()
        req.predicate = NSPredicate(format: "schedule.id == %@ AND scheduledAt == %@",
                                    scheduleId as CVarArg, doseTime as CVarArg)
        req.fetchLimit = 1
        let count = try ctx.count(for: req)
        return count > 0
    }
}
