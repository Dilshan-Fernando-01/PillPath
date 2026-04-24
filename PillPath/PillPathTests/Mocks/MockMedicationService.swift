//
//  MockMedicationService.swift
//  PillPathTests
//
//  In-memory mock conforming to MedicationServiceProtocol.
//  Use this in all ViewModel unit tests instead of hitting CoreData or the network.
//

import Foundation
@testable import PillPath

final class MockMedicationService: MedicationServiceProtocol {

    // Controllable state
    var medications: [Medication] = []
    var shouldThrowOnFetch  = false
    var shouldThrowOnSave   = false
    var shouldThrowOnDelete = false
    var openFDAResults: [Medication] = []

    // Call tracking
    var fetchCallCount  = 0
    var saveCallCount   = 0
    var deleteCallCount = 0
    var searchCallCount = 0

    func fetchAll() throws -> [Medication] {
        fetchCallCount += 1
        if shouldThrowOnFetch { throw TestError.forced }
        return medications
    }

    func fetchActive() throws -> [Medication] {
        if shouldThrowOnFetch { throw TestError.forced }
        return medications.filter(\.isActive)
    }

    func fetch(id: UUID) throws -> Medication? {
        if shouldThrowOnFetch { throw TestError.forced }
        return medications.first { $0.id == id }
    }

    func save(_ medication: Medication) throws {
        saveCallCount += 1
        if shouldThrowOnSave { throw TestError.forced }
        medications.removeAll { $0.id == medication.id }
        medications.append(medication)
    }

    func delete(_ medication: Medication) throws {
        deleteCallCount += 1
        if shouldThrowOnDelete { throw TestError.forced }
        medications.removeAll { $0.id == medication.id }
    }

    func searchOpenFDA(query: String) async throws -> [Medication] {
        searchCallCount += 1
        return openFDAResults
    }
}

enum TestError: Error { case forced }
