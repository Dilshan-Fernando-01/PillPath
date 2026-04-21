import XCTest
import CoreData
@testable import PillPath

final class EventServiceTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: EventService!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        sut   = EventService(coreData: stack)
    }

    override func tearDown() {
        stack = nil
        sut   = nil
        super.tearDown()
    }


    func test_fetchAll_returnsEmptyInitially() throws {
        XCTAssertTrue(try sut.fetchAll().isEmpty)
    }

    func test_fetchAll_returnsSavedEvent() throws {
        let event = makeEvent(title: "Blood Test")
        try sut.save(event)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Blood Test")
    }

    func test_fetchAll_returnsMultipleEvents() throws {
        try sut.save(makeEvent(title: "A"))
        try sut.save(makeEvent(title: "B"))
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 2)
    }

    func test_save_updatesExistingEvent() throws {
        var event = makeEvent(title: "Original")
        try sut.save(event)
        event.title = "Updated"
        try sut.save(event)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Updated")
    }

    func test_save_preservesEventType() throws {
        let event = makeEvent(title: "Appointment", type: .appointment)
        try sut.save(event)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.first?.type, .appointment)
    }

    func test_save_preservesProvider() throws {
        let event = MedicalEvent(title: "Visit", provider: "Dr. Smith", date: .now, type: .appointment)
        try sut.save(event)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.first?.provider, "Dr. Smith")
    }

    func test_save_preservesNotes() throws {
        let event = MedicalEvent(title: "Note", notes: "Take with food", date: .now, type: .note)
        try sut.save(event)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.first?.notes, "Take with food")
    }


    func test_delete_removesEvent() throws {
        let event = makeEvent(title: "ToRemove")
        try sut.save(event)
        try sut.delete(event)
        XCTAssertTrue(try sut.fetchAll().isEmpty)
    }

    func test_delete_onlyRemovesTargetEvent() throws {
        let a = makeEvent(title: "Keep")
        let b = makeEvent(title: "Remove")
        try sut.save(a)
        try sut.save(b)
        try sut.delete(b)
        let result = try sut.fetchAll()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Keep")
    }

    func test_delete_nonExistentEventDoesNotThrow() throws {
        XCTAssertNoThrow(try sut.delete(makeEvent(title: "Ghost")))
    }

    private func makeEvent(title: String, type: MedicalEventType = .note) -> MedicalEvent {
        MedicalEvent(id: UUID(), title: title, notes: nil, provider: nil,
                     medicationIds: [], date: .now, type: type, createdAt: .now)
    }
}
