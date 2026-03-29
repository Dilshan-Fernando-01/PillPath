//
//  AdherenceRecord.swift
//  PillPath — Analytics Module
//

import Foundation

struct AdherenceRecord: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let medicationName: String
    let period: DateInterval
    let totalDoses: Int
    let takenDoses: Int

    var adherencePercentage: Double {
        guard totalDoses > 0 else { return 0 }
        return Double(takenDoses) / Double(totalDoses) * 100
    }

    var grade: AdherenceGrade {
        switch adherencePercentage {
        case 90...100: return .excellent
        case 75..<90:  return .good
        case 50..<75:  return .fair
        default:       return .poor
        }
    }
}

enum AdherenceGrade: String, Codable {
    case excellent = "Excellent"
    case good      = "Good"
    case fair      = "Fair"
    case poor      = "Poor"
}
