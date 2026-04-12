//
//  MockEventService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockEventService: EventServiceProtocol {

    var stubbedEvents: [MedicalEvent] = []
    var fetchAllCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0
    var savedEvent: MedicalEvent?
    var deletedEvent: MedicalEvent?
    var shouldThrow = false

    func fetchAll() throws -> [MedicalEvent] {
        fetchAllCallCount += 1
        if shouldThrow { throw NSError(domain: "MockEventService", code: 1) }
        return stubbedEvents
    }

    func save(_ event: MedicalEvent) throws {
        saveCallCount += 1
        if shouldThrow { throw NSError(domain: "MockEventService", code: 2) }
        savedEvent = event
        stubbedEvents.append(event)
    }

    func delete(_ event: MedicalEvent) throws {
        deleteCallCount += 1
        if shouldThrow { throw NSError(domain: "MockEventService", code: 3) }
        deletedEvent = event
        stubbedEvents.removeAll { $0.id == event.id }
    }
}
