//
//  OCRViewModel.swift
//  PillPath — OCR Module
//

import Foundation
import Combine
import UIKit

@MainActor
final class OCRViewModel: ObservableObject {

    @Published var ocrResult: OCRResult?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private let ocrService: OCRServiceProtocol
    private let medicationService: MedicationServiceProtocol

    init(
        ocrService: OCRServiceProtocol? = nil,
        medicationService: MedicationServiceProtocol? = nil
    ) {
        self.ocrService = ocrService ?? DIContainer.shared.resolve(OCRServiceProtocol.self)
        self.medicationService = medicationService ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
    }

    func scanImage(_ image: UIImage) async {
        isScanning = true
        errorMessage = nil
        do {
            ocrResult = try await ocrService.recognizeText(from: image)
            // TODO: Pass rawText to openFDA to enrich result
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanning = false
    }

    func saveParsedMedication() {
        guard let medication = ocrResult?.parsedMedication else { return }
        do {
            try medicationService.save(medication)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
