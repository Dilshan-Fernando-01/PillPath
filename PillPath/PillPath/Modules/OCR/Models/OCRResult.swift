//
//  OCRResult.swift
//  PillPath — OCR Module
//
//  Represents the output of scanning a medication label or prescription.
//

import Foundation

struct OCRResult: Identifiable {
    let id: UUID
    let rawText: String
    let scannedAt: Date
    var parsedMedication: Medication?  // Populated after NLP parsing

    init(id: UUID = .init(), rawText: String, scannedAt: Date = .now, parsedMedication: Medication? = nil) {
        self.id = id
        self.rawText = rawText
        self.scannedAt = scannedAt
        self.parsedMedication = parsedMedication
    }
}
