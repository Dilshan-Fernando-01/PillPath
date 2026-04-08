//
//  AddMedicationViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class AddMedicationViewModelTests: XCTestCase {

    var sut: AddMedicationViewModel!
    var mockMedicationService: MockMedicationService!
    var mockScheduleService: MockScheduleService!
    var mockDoseTrackingService: MockDoseTrackingService!
    var mockFDAService: MockFDAService!
    var mockEventService: MockEventService!

    override func setUp() {
        super.setUp()
        mockMedicationService   = MockMedicationService()
        mockScheduleService     = MockScheduleService()
        mockDoseTrackingService = MockDoseTrackingService()
        mockFDAService          = MockFDAService()
        mockEventService        = MockEventService()
        sut = AddMedicationViewModel(
            medicationService:    mockMedicationService,
            scheduleService:      mockScheduleService,
            doseTrackingService:  mockDoseTrackingService,
            fdaService:           mockFDAService,
            eventService:         mockEventService
        )
    }

    override func tearDown() {
        sut = nil
        mockMedicationService   = nil
        mockScheduleService     = nil
        mockDoseTrackingService = nil
        mockFDAService          = nil
        mockEventService        = nil
        super.tearDown()
    }

    func test_initialStep_isOne() {
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_initialMedicationName_isEmpty() {
        XCTAssertTrue(sut.medicationName.isEmpty)
    }

    func test_canProceed_falseWhenNameEmpty() {
        sut.medicationName = ""
        XCTAssertFalse(sut.canProceed)
    }

    func test_canProceed_trueWhenNameFilled() {
        sut.medicationName = "Aspirin"
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_falseWhenNameIsOnlyWhitespace() {
        sut.medicationName = "   "
        XCTAssertFalse(sut.canProceed)
    }

    func test_nextStep_incrementsCurrentStep_whenCanProceed() {
        sut.medicationName = "Aspirin"
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, 2)
    }

    func test_nextStep_doesNotAdvance_whenCannotProceed() {
        sut.medicationName = ""
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_previousStep_decrementsCurrentStep() {
        sut.medicationName = "Aspirin"
        sut.nextStep()  
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_previousStep_doesNotGoBelowOne() {
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func test_nextStep_doesNotExceedTotalSteps() {
        sut.goToStep(sut.totalSteps)
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, sut.totalSteps)
    }

    func test_toggleTimeLabel_addsLabel() {
        sut.toggleTimeLabel(.morning)
        XCTAssertTrue(sut.selectedTimeLabels.contains(.morning))
    }

    func test_toggleTimeLabel_removesLabel_whenAlreadySelected() {
        sut.toggleTimeLabel(.morning)
        sut.toggleTimeLabel(.morning)
        XCTAssertFalse(sut.selectedTimeLabels.contains(.morning))
    }

    func test_addCustomTime_appendsToCustomTimes() {
        sut.customTimePickerHour = 10
        sut.customTimePickerMinute = 30
        sut.addCustomTime()
        XCTAssertEqual(sut.customTimes.count, 1)
        XCTAssertEqual(sut.customTimes.first?.hour, 10)
    }

    func test_removeCustomTime_removesFromCustomTimes() {
        sut.addCustomTime()
        let time = sut.customTimes[0]
        sut.removeCustomTime(time)
        XCTAssertTrue(sut.customTimes.isEmpty)
    }

    func test_save_callsMedicationServiceOnce() async {
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertEqual(mockMedicationService.saveCallCount, 1)
    }

    func test_save_callsScheduleServiceOnce() async {
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertEqual(mockScheduleService.saveCallCount, 1)
    }

    func test_save_setsDidSaveOnSuccess() async {
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertTrue(sut.didSave)
    }

    func test_save_setsSavedMedicationOnSuccess() async {
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertNotNil(sut.savedMedication)
        XCTAssertEqual(sut.savedMedication?.name, "Aspirin")
    }

    func test_save_setsErrorOnMedicationServiceFailure() async {
        mockMedicationService.shouldThrowOnSave = true
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertNotNil(sut.saveError)
        XCTAssertFalse(sut.didSave)
    }

    func test_save_setsIsSaving_falseAfterCompletion() async {
        sut.medicationName = "Aspirin"
        sut.selectedTimeLabels = [.morning]
        await sut.save()
        XCTAssertFalse(sut.isSaving)
    }

    func test_prefilled_setsNameAndStepToOne() {
        let vm = AddMedicationViewModel.prefilled(name: "Ibuprofen")
        XCTAssertEqual(vm.medicationName, "Ibuprofen")
        XCTAssertEqual(vm.currentStep, 1)
    }

    func test_editing_setsIsEditingTrue() {
        let med = Medication(name: "Aspirin")
        let vm = AddMedicationViewModel.editing(medication: med)
        XCTAssertTrue(vm.isEditing)
    }

    func test_editing_jumpToReviewStep() {
        let med = Medication(name: "Aspirin")
        let vm = AddMedicationViewModel.editing(medication: med)
        XCTAssertEqual(vm.currentStep, 8)
    }
}
