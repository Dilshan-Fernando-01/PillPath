import XCTest
import CoreData
@testable import PillPath

final class MedicationServiceTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: MedicationService!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        sut   = MedicationService(coreData: stack)
    }

    override func tearDown() {
        stack = nil
        sut   = nil
        super.tearDown()
    }


    func test_fetchAll_returnsEmptyInitially() throws {
        let result = try sut.fetchAll()
        XCTAssertTrue(result.isEmpty)
    }

    func test_fetchAll_returnsSavedMedications() throws {
        let med = makeMedication(name: "Aspirin")
        try sut.save(med)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aspirin")
    }

    func test_fetchAll_returnsMultipleMedications() throws {
        try sut.save(makeMedication(name: "Aspirin"))
        try sut.save(makeMedication(name: "Ibuprofen"))
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 2)
    }


    func test_fetchActive_returnsOnlyActiveMedications() throws {
        try sut.save(makeMedication(name: "Active", isActive: true))
        try sut.save(makeMedication(name: "Stopped", isActive: false))
        let result = try sut.fetchActive()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Active")
    }

    func test_fetchById_returnsMatchingMedication() throws {
        let med = makeMedication(name: "Metformin")
        try sut.save(med)
        let found = try sut.fetch(id: med.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, med.id)
        XCTAssertEqual(found?.name, "Metformin")
    }

    func test_fetchById_returnsNilForUnknownId() throws {
        let result = try sut.fetch(id: UUID())
        XCTAssertNil(result)
    }

    func test_save_updatesExistingMedication() throws {
        var med = makeMedication(name: "Original")
        try sut.save(med)
        med.name = "Updated"
        try sut.save(med)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Updated")
    }

    // MARK: - delete

    func test_delete_removesMedication() throws {
        let med = makeMedication(name: "ToDelete")
        try sut.save(med)
        try sut.delete(med)
        let result = try sut.fetchAll()
        XCTAssertTrue(result.isEmpty)
    }

    func test_delete_onlyRemovesTargetMedication() throws {
        let a = makeMedication(name: "A")
        let b = makeMedication(name: "B")
        try sut.save(a)
        try sut.save(b)
        try sut.delete(a)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "B")
    }

    private func makeMedication(name: String, isActive: Bool = true) -> Medication {
        Medication(
            id: UUID(), name: name, genericName: nil, displayName: nil,
            form: .tablet, dosageAmount: 1, dosageUnit: .pills,
            instructions: nil, notes: nil, photoURL: nil,
            currentQuantity: 30, lowQuantityAlert: false, lowQuantityThreshold: 5,
            isActive: isActive, addedAt: .now, sideEffects: [], interactions: [], statusChange: nil
        )
    }
}
