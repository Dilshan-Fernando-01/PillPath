

import XCTest
import CoreData
@testable import PillPath

final class DoseTrackingServiceTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: DoseTrackingService!

    
    private var medEntity: MedicationEntity!
    private var schedEntity: ScheduleEntity!
    private var medId: UUID!
    private var schedId: UUID!

    override func setUp() {
        super.setUp()
        stack  = CoreDataStack(inMemory: true)
        sut    = DoseTrackingService(coreData: stack)
        medId  = UUID()
        schedId = UUID()

        let ctx = stack.viewContext
        medEntity = MedicationEntity(context: ctx)
        medEntity.id      = medId
        medEntity.name    = "TestMed"
        medEntity.addedAt = .now
        medEntity.isActive = true

        schedEntity = ScheduleEntity(context: ctx)
        schedEntity.id         = schedId
        schedEntity.frequency  = "daily"
        schedEntity.startDate  = .now
        schedEntity.isActive   = true
        schedEntity.doseReminders = false
        schedEntity.medication = medEntity

        stack.save()
    }

    override func tearDown() {
        stack = nil
        sut   = nil
        super.tearDown()
    }

    func test_fetchLogsOnDate_returnsLogsForThatDay() throws {
        insertLog(scheduledAt: todayAt(hour: 8), status: .taken)
        insertLog(scheduledAt: yesterdayAt(hour: 8), status: .taken)

        let result = try sut.fetchLogs(on: .now)
        XCTAssertEqual(result.count, 1)
    }

    func test_fetchLogsOnDate_returnsEmptyForDayWithNoLogs() throws {
        let result = try sut.fetchLogs(on: .now)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - fetchLogs(from:to:)

    func test_fetchLogsFromTo_returnsLogsInRange() throws {
        insertLog(scheduledAt: todayAt(hour: 8), status: .pending)
        insertLog(scheduledAt: yesterdayAt(hour: 8), status: .taken)

        let start = yesterdayAt(hour: 0)
        let end   = todayAt(hour: 23)
        let result = try sut.fetchLogs(from: start, to: end)
        XCTAssertEqual(result.count, 2)
    }

    func test_fetchLogsFromTo_excludesLogsOutsideRange() throws {
        insertLog(scheduledAt: todayAt(hour: 8), status: .pending)
        insertLog(scheduledAt: tomorrowAt(hour: 8), status: .pending)

        let start = todayAt(hour: 0)
        let end   = todayAt(hour: 23)
        let result = try sut.fetchLogs(from: start, to: end)
        XCTAssertEqual(result.count, 1)
    }


    func test_fetchLogsByMedicationId_returnsMatchingLogs() throws {
        let otherId = UUID()
        let otherMed = MedicationEntity(context: stack.viewContext)
        otherMed.id = otherId
        otherMed.name = "Other"
        otherMed.addedAt = .now

        let otherSched = ScheduleEntity(context: stack.viewContext)
        otherSched.id = UUID()
        otherSched.frequency = "daily"
        otherSched.startDate = .now
        otherSched.medication = otherMed
        stack.save()

        insertLog(scheduledAt: todayAt(hour: 8), status: .taken)
        insertLog(scheduledAt: todayAt(hour: 12), status: .taken,
                  med: otherMed, sched: otherSched)

        let result = try sut.fetchLogs(medicationId: medId)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.medicationId, medId)
    }

    func test_markTaken_updateStatusToTaken() throws {
        let log = insertLog(scheduledAt: todayAt(hour: 8), status: .pending)
        try sut.markTaken(log, at: .now)

        let result = try sut.fetchLogs(on: .now)
        XCTAssertEqual(result.first?.status, .taken)
        XCTAssertNotNil(result.first?.takenAt)
    }

    func test_markPending_resetsStatusAndTakenAt() throws {
        let log = insertLog(scheduledAt: todayAt(hour: 8), status: .taken)
        try sut.markPending(log)

        let result = try sut.fetchLogs(on: .now)
        XCTAssertEqual(result.first?.status, .pending)
        XCTAssertNil(result.first?.takenAt)
    }

    func test_markSkipped_updatesStatusToSkipped() throws {
        let log = insertLog(scheduledAt: todayAt(hour: 8), status: .pending)
        try sut.markSkipped(log)

        let result = try sut.fetchLogs(on: .now)
        XCTAssertEqual(result.first?.status, .skipped)
    }

    // MARK: - detectAndMarkMissed

    func test_detectAndMarkMissed_marksPastPendingAsMissed() throws {
        insertLog(scheduledAt: yesterdayAt(hour: 8), status: .pending)
        try sut.detectAndMarkMissed()

        let result = try sut.fetchLogs(on: yesterdayAt(hour: 8))
        XCTAssertEqual(result.first?.status, .missed)
    }

    func test_detectAndMarkMissed_doesNotAffectTakenLogs() throws {
        insertLog(scheduledAt: yesterdayAt(hour: 8), status: .taken)
        try sut.detectAndMarkMissed()

        let result = try sut.fetchLogs(on: yesterdayAt(hour: 8))
        XCTAssertEqual(result.first?.status, .taken)
    }

    @discardableResult
    private func insertLog(scheduledAt: Date, status: DoseStatus,
                           med: MedicationEntity? = nil,
                           sched: ScheduleEntity? = nil) -> DoseLog {
        let ctx = stack.viewContext
        let entity       = DoseLogEntity(context: ctx)
        entity.id        = UUID()
        entity.scheduledAt = scheduledAt
        entity.status    = status.rawValue
        entity.medication = med ?? medEntity
        entity.schedule  = sched ?? schedEntity
        stack.save()

        return DoseLog(
            id: entity.id!, medicationId: (med ?? medEntity).id!,
            scheduleId: (sched ?? schedEntity).id!,
            scheduledAt: scheduledAt, status: status
        )
    }

    private func todayAt(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
    }

    private func yesterdayAt(hour: Int) -> Date {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: yesterday)!
    }

    private func tomorrowAt(hour: Int) -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow)!
    }
}
