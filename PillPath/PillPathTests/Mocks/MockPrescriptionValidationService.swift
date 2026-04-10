//
//  MockPrescriptionValidationService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockPrescriptionValidationService: PrescriptionValidationServiceProtocol {

    var stubbedItems: [ScannedMedicationItem] = [
        ScannedMedicationItem(originalName: "Ibuprofen", confidence: 95, matchStatus: .exact),
        ScannedMedicationItem(originalName: "Amoxicillin", confidence: 70, matchStatus: .partial)
    ]
    var validateCallCount = 0
    var lastCandidates: [String] = []

    func validate(candidates: [String]) async -> [ScannedMedicationItem] {
        validateCallCount += 1
        lastCandidates = candidates
        return stubbedItems
    }
}
