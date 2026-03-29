//
//  MedicationsViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class MedicationsViewModelTests: XCTestCase {

    var sut: MedicationsViewModel!
    var mockService: MockMedicationService!

    override func setUp() {
        super.setUp()
        mockService = MockMedicationService()
        sut = MedicationsViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - loadMedications

    func test_loadMedications_populatesMedications() {
        mockService.medications = [
            Medication(name: "Aspirin", dosage: "100mg"),
            Medication(name: "Ibuprofen", dosage: "200mg")
        ]
        sut.loadMedications()
        XCTAssertEqual(sut.medications.count, 2)
        XCTAssertEqual(mockService.fetchCallCount, 1)
    }

    func test_loadMedications_setsErrorOnFailure() {
        mockService.shouldThrowOnFetch = true
        sut.loadMedications()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.medications.isEmpty)
    }

    // MARK: - addMedication

    func test_addMedication_appendsToList() {
        let med = Medication(name: "Paracetamol", dosage: "500mg")
        sut.addMedication(med)
        XCTAssertEqual(mockService.saveCallCount, 1)
    }

    func test_addMedication_setsErrorOnFailure() {
        mockService.shouldThrowOnSave = true
        sut.addMedication(Medication(name: "Test", dosage: "10mg"))
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - deleteMedication

    func test_deleteMedication_removesFromList() {
        let med = Medication(name: "Aspirin", dosage: "100mg")
        mockService.medications = [med]
        sut.loadMedications()
        sut.deleteMedication(med)
        XCTAssertTrue(sut.medications.isEmpty)
    }

    // MARK: - searchOpenFDA

    func test_searchOpenFDA_updatesSearchResults() async {
        mockService.openFDAResults = [Medication(name: "FDA Drug", dosage: "50mg")]
        await sut.searchOpenFDA(query: "aspirin")
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertFalse(sut.isLoading)
    }

    func test_searchOpenFDA_emptyQuery_doesNotSearch() async {
        await sut.searchOpenFDA(query: "")
        XCTAssertEqual(mockService.searchCallCount, 0)
    }
}
