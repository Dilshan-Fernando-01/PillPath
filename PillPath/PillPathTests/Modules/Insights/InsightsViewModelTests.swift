//
//  InsightsViewModelTests.swift
//  PillPathTests — Insights Module
//

import XCTest
@testable import PillPath

@MainActor
final class InsightsViewModelTests: XCTestCase {

    private var doseService: MockDoseTrackingService!
    private var medService: MockMedicationService!
    private var eventService: MockEventService!
    private var sut: InsightsViewModel!

    override func setUp() {
        super.setUp()
        doseService  = MockDoseTrackingService()
        medService   = MockMedicationService()
        eventService = MockEventService()
        sut = InsightsViewModel(
            doseService:  doseService,
            medService:   medService,
            eventService: eventService
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState() {
        XCTAssertEqual(sut.period, .week)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.takenCount, 0)
        XCTAssertEqual(sut.missedCount, 0)
        XCTAssertEqual(sut.skippedCount, 0)
        XCTAssertEqual(sut.currentStreak, 0)
        XCTAssertEqual(sut.adherenceRate, 0)
        XCTAssertTrue(sut.dailyStats.isEmpty)
        XCTAssertTrue(sut.medicationStats.isEmpty)
        XCTAssertTrue(sut.upcomingEvents.isEmpty)
    }

    // MARK: - load()

    func test_load_withNoLogs_zerosStats() {
        doseService.logs = []
        medService.medications = []
        sut.load()

        XCTAssertEqual(sut.takenCount, 0)
        XCTAssertEqual(sut.missedCount, 0)
        XCTAssertEqual(sut.adherenceRate, 0)
        XCTAssertEqual(sut.dailyStats.count, 7)
    }

    func test_load_computesSummaryFromLogs() {
        let medId = UUID()
        let schedId = UUID()
        let now = Date.now
        doseService.logs = [
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: now, status: .taken),
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: now, status: .taken),
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: now, status: .missed),
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: now, status: .skipped)
        ]
        sut.load()

        XCTAssertEqual(sut.takenCount, 2)
        XCTAssertEqual(sut.missedCount, 1)
        XCTAssertEqual(sut.skippedCount, 1)
        XCTAssertEqual(sut.adherenceRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func test_load_producesDailyStatsForWeekPeriod() {
        sut.load()
        XCTAssertEqual(sut.dailyStats.count, 7)
    }

    func test_load_producesDailyStatsForMonthPeriod() {
        sut.period = .month
        sut.load()
        XCTAssertEqual(sut.dailyStats.count, 30)
    }

    func test_load_computesMedicationStats() {
        let medId = UUID()
        let schedId = UUID()
        let med = makeMedication(id: medId, name: "Aspirin")
        medService.medications = [med]
        doseService.logs = [
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: .now, status: .taken),
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: .now, status: .missed)
        ]
        sut.load()

        XCTAssertEqual(sut.medicationStats.count, 1)
        XCTAssertEqual(sut.medicationStats.first?.name, "Aspirin")
        XCTAssertEqual(sut.medicationStats.first?.takenCount, 1)
        XCTAssertEqual(sut.medicationStats.first?.missedCount, 1)
        XCTAssertEqual(sut.medicationStats.first?.adherenceRate, 0.5, accuracy: 0.001)
    }

    func test_load_skipsUnknownMedicationInStats() {
        doseService.logs = [
            DoseLog(id: UUID(), medicationId: UUID(), scheduleId: UUID(), scheduledAt: .now, status: .taken)
        ]
        medService.medications = []
        sut.load()
        XCTAssertTrue(sut.medicationStats.isEmpty)
    }

    // MARK: - changePeriod

    func test_changePeriod_updatesAndReloads() {
        sut.changePeriod(.month)
        XCTAssertEqual(sut.period, .month)
        XCTAssertEqual(sut.dailyStats.count, 30)
    }

    // MARK: - Streak

    func test_streak_isZeroWithNoLogs() {
        doseService.logs = []
        sut.load()
        XCTAssertEqual(sut.currentStreak, 0)
    }

    func test_streak_countsConsecutiveTakenDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let schedId = UUID()
        let medId = UUID()

        var logs: [DoseLog] = []
        for offset in 0..<3 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            logs.append(DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId,
                                scheduledAt: day.addingTimeInterval(3600), status: .taken))
        }
        doseService.logs = logs
        sut.load()

        XCTAssertEqual(sut.currentStreak, 3)
    }

    // MARK: - Upcoming Events

    func test_upcomingEvents_filtersToNext7Days() {
        let now = Date.now
        let tomorrow = now.addingTimeInterval(86400)
        let inTenDays = now.addingTimeInterval(864000)
        let yesterday = now.addingTimeInterval(-86400)

        eventService.stubbedEvents = [
            MedicalEvent(id: UUID(), title: "Checkup", date: tomorrow, type: .appointment),
            MedicalEvent(id: UUID(), title: "Far future", date: inTenDays, type: .appointment),
            MedicalEvent(id: UUID(), title: "Past event", date: yesterday, type: .note)
        ]
        sut.load()

        XCTAssertEqual(sut.upcomingEvents.count, 1)
        XCTAssertEqual(sut.upcomingEvents.first?.title, "Checkup")
    }

    func test_upcomingEvents_cappedAtFive() {
        let base = Date.now.addingTimeInterval(3600)
        eventService.stubbedEvents = (0..<8).map { i in
            MedicalEvent(id: UUID(), title: "Event \(i)",
                         date: base.addingTimeInterval(Double(i) * 3600), type: .note)
        }
        sut.load()
        XCTAssertEqual(sut.upcomingEvents.count, 5)
    }

    // MARK: - Tips

    func test_tips_returnsNoDataTipWhenEmpty() {
        doseService.logs = []
        sut.load()
        XCTAssertEqual(sut.tips.count, 1)
        XCTAssertEqual(sut.tips.first?.accentColor, .info)
    }

    func test_tips_highAdherenceProducesSuccessTip() {
        let medId = UUID()
        let schedId = UUID()
        doseService.logs = (0..<10).map { _ in
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId,
                    scheduledAt: .now, status: .taken)
        }
        medService.medications = [makeMedication(id: medId, name: "Med")]
        sut.load()
        let successTips = sut.tips.filter { $0.accentColor == .success }
        XCTAssertFalse(successTips.isEmpty)
    }

    // MARK: - InsightsPeriod

    func test_periodDisplayNames() {
        XCTAssertEqual(InsightsPeriod.week.displayName, "This Week")
        XCTAssertEqual(InsightsPeriod.month.displayName, "This Month")
    }

    func test_periodDays() {
        XCTAssertEqual(InsightsPeriod.week.days, 7)
        XCTAssertEqual(InsightsPeriod.month.days, 30)
    }

    // MARK: - DailyBarData

    func test_dailyBarData_totalIsSum() {
        let bar = DailyBarData(day: .now, taken: 3, missed: 1, skipped: 2)
        XCTAssertEqual(bar.total, 6)
    }

    func test_dailyBarData_shortLabel_isThreeChars() {
        let bar = DailyBarData(day: .now, taken: 0, missed: 0, skipped: 0)
        XCTAssertEqual(bar.shortLabel.count, 3)
    }

    // MARK: - MedicationStat adherenceRate

    func test_medicationStat_adherenceRate_zeroWhenNoScheduled() {
        let stat = MedicationStat(medicationId: UUID(), name: "X", dosageDisplay: "1",
                                  takenCount: 0, totalScheduled: 0, missedCount: 0)
        XCTAssertEqual(stat.adherenceRate, 0)
    }

    func test_medicationStat_adherenceRate_calculation() {
        let stat = MedicationStat(medicationId: UUID(), name: "X", dosageDisplay: "1",
                                  takenCount: 3, totalScheduled: 4, missedCount: 1)
        XCTAssertEqual(stat.adherenceRate, 0.75, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeMedication(id: UUID = UUID(), name: String = "Test Med") -> Medication {
        Medication(
            id: id, name: name, genericName: nil, displayName: nil,
            form: .tablet, dosageAmount: 1, dosageUnit: .pills,
            instructions: nil, notes: nil, photoURL: nil,
            currentQuantity: 30, lowQuantityAlert: false, lowQuantityThreshold: 5,
            isActive: true, addedAt: .now, sideEffects: [], interactions: [], statusChange: nil
        )
    }
}
