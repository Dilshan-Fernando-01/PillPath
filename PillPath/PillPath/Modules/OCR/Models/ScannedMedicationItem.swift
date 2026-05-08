
import Foundation

struct ScannedMedicationItem: Identifiable {
    let id: UUID
    var originalName: String          
    var fdaMatchName: String?         
    var fdaResult: MedicationSearchResult?
    var confidence: Int               
    var matchStatus: MatchStatus
    var userEditedName: String        
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


    enum MatchStatus {
        case exact      
        case partial    
        case none       

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
        case pending   
        case accepted  
        case rejected  
    }


    var displayName: String { userEditedName.isEmpty ? originalName : userEditedName }

    var isAccepted: Bool { action == .accepted }
    var isRejected: Bool { action == .rejected }
}
