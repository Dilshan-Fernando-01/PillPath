//
//  MockOCRService.swift
//  PillPathTests
//

import UIKit
@testable import PillPath

final class MockOCRService: OCRServiceProtocol {

    var stubbedResult: OCRResult = OCRResult(id: UUID(), rawText: "Ibuprofen 400mg")
    var recognizeCallCount = 0
    var shouldThrow = false

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        recognizeCallCount += 1
        if shouldThrow { throw OCRError.invalidImage }
        return stubbedResult
    }
}
