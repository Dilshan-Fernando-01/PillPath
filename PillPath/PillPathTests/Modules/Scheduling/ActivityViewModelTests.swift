//
//  ActivityViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class ActivityViewModelTests: XCTestCase {

    var sut: ActivityViewModel!
    var mockScheduleService: MockScheduleService!
    var mockDoseTrackingService: MockDoseTrackingService!
    var mockMedicationService: MockMedicationService!
    var mockEventService: MockEventService!

    override func setUp() {
        super.setUp()
        mockScheduleService     = MockScheduleService()
        mockDoseTrackingService = MockDoseTrackingService()
        mockMedicationService   = MockMedicationService()
        mockEventService        = MockEventService()
        sut = ActivityViewModel(
            scheduleService:     mockScheduleService,
            doseTrackingService: mockDoseTrackingService,
            medicationService:   mockMedicationService,
            eventService:        mockEventService
        )
    }

    override func tearDown() {
        sut = nil
        mockScheduleService     = nil
        mockDoseTrackingService = nil
        mockMedicationService   = nil
        mockEventService        = nil
        super.tearDown()
    }


    func test_loadMedications_separatesActiveAndStopped() {
        mockMedicationService.medications = [
            Medication(name: "Aspirin",     isActive: true),
            Medication(name: "Ibuprofen",   isActive: false),
            Medication(name: "Paracetamol", isActive: true)
        ]
        sut.loadMedications()
        XCTAssertEqual(sut.activeMedications.count, 2)
        XCTAssertEqual(sut.stoppedMedications.count, 1)
    }

    func test_loadMedications_setsErrorOnFailure() {
        mockMedicationService.shouldThrowOnFetch = true
        sut.loadMedications()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadMedications_emptyWhenNoMedications() {
        mockMedicationService.medications = []
        sut.loadMedications()
        XCTAssertTrue(sut.activeMedications.isEmpty)
        XCTAssertTrue(sut.stoppedMedications.isEmpty)
    }


    func test_loadEvents_populatesAllEvents() {
        let event1 = MedicalEvent(title: "Blood Test", date: .now)
        let event2 = MedicalEvent(title: "X-Ray", date: .now)
        mockEventService.stubbedEvents = [event1, event2]
        sut.loadEvents()
        XCTAssertEqual(sut.allEvents.count, 2)
    }

    func test_loadEvents_setsErrorOnFailure() {
        mockEventService.shouldThrow = true
        sut.loadEvents()
        XCTAssertNotNil(sut.errorMessage)
    }


    func test_saveEvent_callsEventService() {
        let event = MedicalEvent(title: "Checkup", date: .now)
        sut.saveEvent(event)
        XCTAssertEqual(mockEventService.saveCallCount, 1)
    }

    func test_saveEvent_reloadsEventsAfterSave() {
        let event = MedicalEvent(title: "Checkup", date: .now)
        sut.saveEvent(event)
        XCTAssertGreaterThanOrEqual(mockEventService.fetchAllCallCount, 1)
    }


    func test_deleteEvent_callsEventService() {
        let event = MedicalEvent(title: "Checkup", date: .now)
        mockEventService.stubbedEvents = [event]
        sut.deleteEvent(event)
        XCTAssertEqual(mockEventService.deleteCallCount, 1)
    }


    func test_toggleActive_savesUpdatedMedication() {
        let med = Medication(name: "Aspirin", isActive: true)
        mockMedicationService.medications = [med]
        let change = MedicationStatusChange(isActive: false, effectiveDate: .now, reason: "Stopped")
        sut.toggleActive(med, change: change)
        XCTAssertEqual(mockMedicationService.saveCallCount, 1)
    }



    func test_filteredActiveMedications_returnsAllWhenSearchEmpty() {
        sut.activeMedications = [
            Medication(name: "Aspirin"),
            Medication(name: "Ibuprofen")
        ]
        sut.medicationSearch = ""
        XCTAssertEqual(sut.filteredActiveMedications.count, 2)
    }

    func test_filteredActiveMedications_filtersBySearch() {
        sut.activeMedications = [
            Medication(name: "Aspirin"),
            Medication(name: "Ibuprofen")
        ]
        sut.medicationSearch = "aspirin"
        XCTAssertEqual(sut.filteredActiveMedications.count, 1)
        XCTAssertEqual(sut.filteredActiveMedications.first?.name, "Aspirin")
    }

    func test_weekDays_returns7Days() {
        XCTAssertEqual(sut.weekDays.count, 7)
    }

    func test_changeWeek_incrementsWeekOffset() {
        sut.changeWeek(by: 1)
        XCTAssertEqual(sut.weekOffset, 1)
    }

    func test_changeWeek_decrementsWeekOffset() {
        sut.changeWeek(by: -1)
        XCTAssertEqual(sut.weekOffset, -1)
    }


    func test_selectDate_updatesSelectedDate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        sut.selectDate(tomorrow)
        XCTAssertTrue(Calendar.current.isDate(sut.selectedDate, inSameDayAs: tomorrow))
    }
}
