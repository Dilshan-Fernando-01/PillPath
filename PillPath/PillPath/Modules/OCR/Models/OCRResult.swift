
import Foundation

struct OCRResult: Identifiable {
    let id: UUID
    let rawText: String
    let scannedAt: Date
    var parsedMedication: Medication?  

    init(id: UUID = .init(), rawText: String, scannedAt: Date = .now, parsedMedication: Medication? = nil) {
        self.id = id
        self.rawText = rawText
        self.scannedAt = scannedAt
        self.parsedMedication = parsedMedication
    }
}
