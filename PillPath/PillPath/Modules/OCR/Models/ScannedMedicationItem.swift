//
//  ScannedMedicationItem.swift
//  PillPath — OCR Module
//
//  Represents one medication candidate extracted from a prescription scan.
//

import Foundation

struct ScannedMedicationItem: Identifiable {
    let id: UUID
    var originalName: String          // Raw text from OCR
    var fdaMatchName: String?         // Best openFDA brand/generic match
    var fdaResult: MedicationSearchResult?
    var confidence: Int               // 0–100 similarity score
    var matchStatus: MatchStatus
    var userEditedName: String        // Editable by the user; starts == fdaMatchName ?? originalName
    var action: ItemAction
    var suggestedDosageAmount: Double
    var suggestedDosageUnit: DosageUnit
    var suggestedForm: MedicationForm

    init(
        id: UUID = .init(),
        originalName: String,
        fdaMatchName: String? = nil,
        fdaResult: MedicationSearchResult? = nil,
        confidence: Int = 0,
        matchStatus: MatchStatus = .none,
        suggestedDosageAmount: Double = 1.0,
        suggestedDosageUnit: DosageUnit = .pills,
        suggestedForm: MedicationForm = .tablet
    ) {
        self.id = id
        self.originalName = originalName
        self.fdaMatchName = fdaMatchName
        self.fdaResult = fdaResult
        self.confidence = confidence
        self.matchStatus = matchStatus
        self.userEditedName = fdaMatchName ?? originalName
        self.action = matchStatus == .none ? .pending : (confidence >= 75 ? .accepted : .pending)
        self.suggestedDosageAmount = suggestedDosageAmount
        self.suggestedDosageUnit   = suggestedDosageUnit
        self.suggestedForm         = suggestedForm
    }

    // MARK: - Nested Enums

    enum MatchStatus {
        case exact      // ≥ 95 % similarity
        case partial    // 60–94 %
        case none       // < 60 %

        var displayName: String {
            switch self {
            case .exact:   return "Exact match"
            case .partial: return "Partial match"
            case .none:    return "No match"
            }
        }

        var confidenceLabel: String {
            switch self {
            case .exact:   return "HIGH CONFIDENCE"
            case .partial: return "REVIEW"
            case .none:    return "NO MATCH"
            }
        }
    }

    enum ItemAction {
        case pending   // Not yet decided
        case accepted  // User confirmed
        case rejected  // User removed
    }

    // MARK: - Helpers

    var displayName: String { userEditedName.isEmpty ? originalName : userEditedName }

    var isAccepted: Bool { action == .accepted }
    var isRejected: Bool { action == .rejected }
}
