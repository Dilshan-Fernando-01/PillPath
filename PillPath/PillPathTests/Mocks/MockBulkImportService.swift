//
//  MockBulkImportService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockBulkImportService: BulkImportServiceProtocol {

    var stubbedMedications: [Medication] = []
    var importCallCount = 0
    var lastImportedItems: [ScannedMedicationItem] = []
    var shouldThrow = false

    func importMedications(_ items: [ScannedMedicationItem]) async throws -> [Medication] {
        importCallCount += 1
        lastImportedItems = items
        if shouldThrow { throw NSError(domain: "MockBulkImportService", code: 1) }
        return stubbedMedications
    }
}
