//
//  PrescriptionScanViewModel.swift
//  PillPath — OCR Module
//
//  Orchestrates the full scan → extract → validate → import pipeline.
//

import Foundation
import UIKit
import Combine

@MainActor
final class PrescriptionScanViewModel: ObservableObject {

    // MARK: - Flow state

    enum ScanStep {
        case camera       // Step 1: capture image
        case analyzing    // Step 2: OCR + FDA validation
        case review       // Step 3: user reviews/edits list
        case done         // Step 5: success
    }

    @Published var step: ScanStep = .camera
    @Published var scannedItems: [ScannedMedicationItem] = []
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isImporting = false
    @Published var savedMedications: [Medication] = []

    // Manual addition (+ Add Another Manually)
    @Published var showManualEntry = false

    // Quick-edit sheet
    @Published var editingItem: ScannedMedicationItem?

    // Advanced edit (redirect to Add Medication stepper)
    @Published var advancedEditViewModel: AddMedicationViewModel?

    // MARK: - Services

    private let ocrService: OCRServiceProtocol
    private let extractionService: MedicationExtractionServiceProtocol
    private let validationService: PrescriptionValidationServiceProtocol
    private let importService: BulkImportServiceProtocol

    init(
        ocrService: OCRServiceProtocol? = nil,
        extractionService: MedicationExtractionServiceProtocol? = nil,
        validationService: PrescriptionValidationServiceProtocol? = nil,
        importService: BulkImportServiceProtocol? = nil
    ) {
        self.ocrService        = ocrService        ?? OCRService()
        self.extractionService = extractionService ?? MedicationExtractionService()
        self.validationService = validationService ?? PrescriptionValidationService()
        self.importService     = importService     ?? BulkImportService()
    }

    // MARK: - Pipeline

    /// Called when user captures or picks an image.
    func processImage(_ image: UIImage) {
        capturedImage = image
        step = .analyzing
        errorMessage = nil

        Task {
            do {
                // 1. OCR
                let ocrResult = try await ocrService.recognizeText(from: image)
                guard !ocrResult.rawText.isEmpty else {
                    errorMessage = "No text found in the image. Try a clearer photo."
                    step = .camera
                    return
                }

                // 2. Extract candidates
                let candidates = extractionService.extractCandidates(from: ocrResult.rawText)
                guard !candidates.isEmpty else {
                    errorMessage = "No medication names detected. You can add them manually."
                    // Show review with empty state + manual add
                    scannedItems = []
                    step = .review
                    return
                }

                // 3. Validate against FDA (concurrent)
                let validated = await validationService.validate(candidates: candidates)

                scannedItems = validated
                step = .review

            } catch {
                errorMessage = error.localizedDescription
                step = .camera
            }
        }
    }

    // MARK: - Item actions (Review screen)

    func accept(_ item: ScannedMedicationItem) {
        update(item) { $0.action = .accepted }
    }

    func reject(_ item: ScannedMedicationItem) {
        update(item) { $0.action = .rejected }
    }

    func acceptAll() {
        for i in scannedItems.indices where scannedItems[i].action != .rejected {
            scannedItems[i].action = .accepted
        }
    }

    func addManual(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let item = ScannedMedicationItem(
            originalName: name,
            fdaMatchName: name,
            confidence: 100,
            matchStatus: .exact
        )
        var new = item
        new.action = .accepted
        scannedItems.append(new)
    }

    func updateItemName(_ item: ScannedMedicationItem, newName: String) {
        update(item) {
            $0.userEditedName = newName
            $0.action = .accepted
        }
    }

    func updateItemDosage(_ item: ScannedMedicationItem, amount: Double, unit: DosageUnit) {
        update(item) {
            $0.suggestedDosageAmount = amount
            $0.suggestedDosageUnit   = unit
        }
    }

    func openAdvancedEdit(for item: ScannedMedicationItem) {
        let vm = AddMedicationViewModel.prefilled(
            name: item.displayName,
            form: item.suggestedForm,
            dosage: item.suggestedDosageAmount,
            unit: item.suggestedDosageUnit
        )
        advancedEditViewModel = vm
        // Mark rejected so it won't double-import
        reject(item)
    }

    // MARK: - Import

    var acceptedCount: Int { scannedItems.filter { $0.action == .accepted }.count }

    func importAll() {
        guard acceptedCount > 0 else { return }
        isImporting = true

        Task {
            do {
                savedMedications = try await importService.importMedications(scannedItems)
                step = .done
            } catch {
                errorMessage = error.localizedDescription
            }
            isImporting = false
        }
    }

    // MARK: - Reset

    func scanAnother() {
        capturedImage = nil
        scannedItems = []
        savedMedications = []
        errorMessage = nil
        step = .camera
    }

    // MARK: - Private

    private func update(_ item: ScannedMedicationItem, mutation: (inout ScannedMedicationItem) -> Void) {
        guard let idx = scannedItems.firstIndex(where: { $0.id == item.id }) else { return }
        mutation(&scannedItems[idx])
    }
}
