//
//  PrescriptionScanViewModelTests.swift
//  PillPathTests
//

import XCTest
import UIKit
@testable import PillPath

@MainActor
final class PrescriptionScanViewModelTests: XCTestCase {

    var sut: PrescriptionScanViewModel!
    var mockOCRService: MockOCRService!
    var mockExtractionService: MockMedicationExtractionService!
    var mockValidationService: MockPrescriptionValidationService!
    var mockImportService: MockBulkImportService!

    override func setUp() {
        super.setUp()
        mockOCRService         = MockOCRService()
        mockExtractionService  = MockMedicationExtractionService()
        mockValidationService  = MockPrescriptionValidationService()
        mockImportService      = MockBulkImportService()
        sut = PrescriptionScanViewModel(
            ocrService:        mockOCRService,
            extractionService: mockExtractionService,
            validationService: mockValidationService,
            importService:     mockImportService
        )
    }

    override func tearDown() {
        sut = nil
        mockOCRService        = nil
        mockExtractionService = nil
        mockValidationService = nil
        mockImportService     = nil
        super.tearDown()
    }


    func test_initialState_isCamera() {
        XCTAssertEqual(sut.step, .camera)
    }

    func test_initialScannedItems_isEmpty() {
        XCTAssertTrue(sut.scannedItems.isEmpty)
    }


    func test_accept_changesItemActionToAccepted() {
        let item = ScannedMedicationItem(originalName: "Aspirin")
        sut.scannedItems = [item]
        sut.accept(item)
        XCTAssertEqual(sut.scannedItems.first?.action, .accepted)
    }

    func test_reject_changesItemActionToRejected() {
        let item = ScannedMedicationItem(originalName: "Aspirin")
        sut.scannedItems = [item]
        sut.reject(item)
        XCTAssertEqual(sut.scannedItems.first?.action, .rejected)
    }

    func test_acceptAll_setsAllNonRejectedToAccepted() {
        let item1 = ScannedMedicationItem(originalName: "Aspirin")
        var item2 = ScannedMedicationItem(originalName: "Ibuprofen")
        item2.action = .rejected
        sut.scannedItems = [item1, item2]
        sut.acceptAll()
        XCTAssertEqual(sut.scannedItems[0].action, .accepted)
        XCTAssertEqual(sut.scannedItems[1].action, .rejected) 
    }

    func test_addManual_appendsNewItemAsAccepted() {
        sut.addManual(name: "Paracetamol")
        XCTAssertEqual(sut.scannedItems.count, 1)
        XCTAssertEqual(sut.scannedItems.first?.originalName, "Paracetamol")
        XCTAssertEqual(sut.scannedItems.first?.action, .accepted)
    }

    func test_addManual_doesNothingForEmptyName() {
        sut.addManual(name: "   ")
        XCTAssertTrue(sut.scannedItems.isEmpty)
    }


    func test_acceptedCount_countsOnlyAccepted() {
        var item1 = ScannedMedicationItem(originalName: "Aspirin")
        item1.action = .accepted
        var item2 = ScannedMedicationItem(originalName: "Ibuprofen")
        item2.action = .rejected
        var item3 = ScannedMedicationItem(originalName: "Cetirizine")
        item3.action = .pending
        sut.scannedItems = [item1, item2, item3]
        XCTAssertEqual(sut.acceptedCount, 1)
    }

    func test_importAll_callsBulkImportService() async {
        var item = ScannedMedicationItem(originalName: "Aspirin")
        item.action = .accepted
        sut.scannedItems = [item]
        mockImportService.stubbedMedications = [Medication(name: "Aspirin")]

        sut.importAll()
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(mockImportService.importCallCount, 1)
    }

    func test_importAll_doesNotCallImportWhenNothingAccepted() {
        sut.scannedItems = []
        sut.importAll()
        XCTAssertEqual(mockImportService.importCallCount, 0)
    }

    func test_importAll_setsStepToDone_onSuccess() async {
        var item = ScannedMedicationItem(originalName: "Aspirin")
        item.action = .accepted
        sut.scannedItems = [item]
        mockImportService.stubbedMedications = [Medication(name: "Aspirin")]

        sut.importAll()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.step, .done)
    }

    func test_scanAnother_resetsStateToCamera() {
        sut.scannedItems = [ScannedMedicationItem(originalName: "Aspirin")]
        sut.step = .done
        sut.scanAnother()
        XCTAssertEqual(sut.step, .camera)
        XCTAssertTrue(sut.scannedItems.isEmpty)
        XCTAssertNil(sut.capturedImage)
        XCTAssertNil(sut.errorMessage)
    }

    func test_presentCrop_setsCropStep() {
        let image = UIImage()
        sut.presentCrop(image)
        XCTAssertEqual(sut.step, .crop)
    }
}
