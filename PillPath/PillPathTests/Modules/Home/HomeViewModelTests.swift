//
//  HomeViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class HomeViewModelTests: XCTestCase {

    var sut: HomeViewModel!
    var mockScheduleService: MockScheduleService!
    var mockDoseTrackingService: MockDoseTrackingService!
    var mockMedicationService: MockMedicationService!

    override func setUp() {
        super.setUp()
        mockScheduleService      = MockScheduleService()
        mockDoseTrackingService  = MockDoseTrackingService()
        mockMedicationService    = MockMedicationService()
        sut = HomeViewModel(
            scheduleService:      mockScheduleService,
            doseTrackingService:  mockDoseTrackingService,
            medicationService:    mockMedicationService
        )
    }

    override func tearDown() {
        sut = nil
        mockScheduleService     = nil
        mockDoseTrackingService = nil
        mockMedicationService   = nil
        super.tearDown()
    }

    func test_loadTodaysDoses_setsIsLoading_falseAfterLoad() {
        sut.loadDoses(for: .now)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadTodaysDoses_emptyWhenNoMedications() {
        mockMedicationService.medications = []
        mockScheduleService.schedules = []
        sut.loadDoses(for: .now)
        let totalItems = sut.timeOfDayGroups.flatMap(\.allItems)
        XCTAssertTrue(totalItems.isEmpty)
    }

    func test_loadTodaysDoses_groupsByTimeOfDay() {
        let medId = UUID()
        let med = Medication(id: medId, name: "Aspirin", isActive: true)
        mockMedicationService.medications = [med]

        let morningTime = ScheduleTime(hour: 8, minute: 0)
        let eveningTime = ScheduleTime(hour: 18, minute: 0)
        let schedule = MedicationSchedule(
            medicationId: medId,
            scheduleTimes: [morningTime, eveningTime],
            startDate: Calendar.current.startOfDay(for: .now)
        )
        mockScheduleService.schedules = [schedule]

        sut.loadDoses(for: .now)

        let nonEmptyGroups = sut.timeOfDayGroups.filter { !$0.isEmpty }
        XCTAssertFalse(nonEmptyGroups.isEmpty)
    }

    func test_loadTodaysDoses_setsErrorOnServiceFailure() {
        mockMedicationService.shouldThrowOnFetch = true
        sut.loadDoses(for: .now)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadTodaysDoses_setsErrorOnDoseTrackingFailure() {
        mockDoseTrackingService.shouldThrow = true
        sut.loadDoses(for: .now)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_nextDose_returnsNilWhenNoPendingDoses() {
        mockMedicationService.medications = []
        mockScheduleService.schedules = []
        sut.loadDoses(for: .now)
        XCTAssertNil(sut.nextDose)
    }

    func test_nextDose_returnsNilForPastDate() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        sut.loadDoses(for: yesterday)
        XCTAssertNil(sut.nextDose)
    }

    func test_markTaken_callsDoseTrackingServiceOnce() {
        let logId = UUID()
        let medId = UUID()
        let schedId = UUID()
        let item = DoseDisplayItem(
            id: logId, medicationId: medId, scheduleId: schedId,
            medicationName: "Aspirin", dosageDisplay: "100mg",
            medicationCategory: nil, usageNote: nil,
            scheduledAt: .now, timeLabel: .morning,
            mealTiming: .none, status: .pending, logId: logId
        )
        mockDoseTrackingService.logs = [
            DoseLog(id: logId, medicationId: medId, scheduleId: schedId,
                    scheduledAt: .now, status: .pending)
        ]
        sut.markTaken(item)
        XCTAssertEqual(mockDoseTrackingService.markTakenCallCount, 1)
    }

    func test_markTaken_doesNotCallServiceWhenNoLogId() {
        let item = DoseDisplayItem(
            id: UUID(), medicationId: UUID(), scheduleId: UUID(),
            medicationName: "Aspirin", dosageDisplay: "100mg",
            medicationCategory: nil, usageNote: nil,
            scheduledAt: .now, timeLabel: .morning,
            mealTiming: .none, status: .pending, logId: nil  
        )
        sut.markTaken(item)
        XCTAssertEqual(mockDoseTrackingService.markTakenCallCount, 0)
    }

    func test_selectDate_changesSelectedDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        sut.selectDate(tomorrow)
        XCTAssertTrue(Calendar.current.isDate(sut.selectedDate, inSameDayAs: tomorrow))
    }

    func test_selectDate_normalisesToStartOfDay() {
        let date = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: .now)!
        sut.selectDate(date)
        let components = Calendar.current.dateComponents([.hour, .minute], from: sut.selectedDate)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }
}
