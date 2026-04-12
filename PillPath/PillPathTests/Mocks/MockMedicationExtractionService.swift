//
//  MockMedicationExtractionService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockMedicationExtractionService: MedicationExtractionServiceProtocol {

    var stubbedCandidates: [String] = ["Ibuprofen", "Amoxicillin"]
    var extractCallCount = 0
    var lastRawText: String?

    func extractCandidates(from rawText: String) -> [String] {
        extractCallCount += 1
        lastRawText = rawText
        return stubbedCandidates
    }
}
