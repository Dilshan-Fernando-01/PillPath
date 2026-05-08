

import Foundation
import UIKit
import Combine

@MainActor
final class PrescriptionScanViewModel: ObservableObject {

  

    enum ScanStep {
        case camera       
        case crop         
        case analyzing    
        case review      
        case done         
    }

    @Published var step: ScanStep = .camera
    @Published var scannedItems: [ScannedMedicationItem] = []
    @Published var capturedImage: UIImage?
    @Published var rawImage: UIImage?      
    @Published var errorMessage: String?
    @Published var isImporting = false
    @Published var savedMedications: [Medication] = []

   
    @Published var showManualEntry = false

   
    @Published var editingItem: ScannedMedicationItem?

  
    @Published var advancedEditViewModel: AddMedicationViewModel?

  

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

    func presentCrop(_ image: UIImage) {
        rawImage = image
        step = .crop
    }

   func processFromCrop(_ image: UIImage) {
        processImage(image)
    }

    func processImage(_ image: UIImage) {
        capturedImage = image
        step = .analyzing
        errorMessage = nil

        Task {
            do {
           
                let ocrResult = try await ocrService.recognizeText(from: image)
                guard !ocrResult.rawText.isEmpty else {
                    errorMessage = "No text found in the image. Try a clearer photo."
                    step = .camera
                    return
                }

               
                let candidates = extractionService.extractCandidates(from: ocrResult.rawText)
                guard !candidates.isEmpty else {
                    errorMessage = "No medication names detected. You can add them manually."
                      scannedItems = []
                    step = .review
                    return
                }

              
                let validated = await validationService.validate(candidates: candidates)

                scannedItems = validated
                step = .review

            } catch {
                errorMessage = error.localizedDescription
                step = .camera
            }
        }
    }



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
       
        reject(item)
    }

   

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



    func scanAnother() {
        capturedImage = nil
        rawImage = nil
        scannedItems = []
        savedMedications = []
        errorMessage = nil
        step = .camera
    }

    

    private func update(_ item: ScannedMedicationItem, mutation: (inout ScannedMedicationItem) -> Void) {
        guard let idx = scannedItems.firstIndex(where: { $0.id == item.id }) else { return }
        mutation(&scannedItems[idx])
    }
}
