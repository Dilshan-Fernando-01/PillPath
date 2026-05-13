
import Foundation
import SwiftUI

struct InAppNotification: Identifiable {
    let id: UUID
    let userId: String
    let title: String
    let body: String
    let type: InAppNotificationType
    var isRead: Bool
    let createdAt: Date
    let deepLinkTarget: String?
}

enum InAppNotificationType: String {
    case missedDose    = "missedDose"
    case lowStock      = "lowStock"
    case doseReminder  = "doseReminder"
    case eventReminder = "eventReminder"

    var icon: String {
        switch self {
        case .missedDose:    return "exclamationmark.circle.fill"
        case .lowStock:      return "pills.fill"
        case .doseReminder:  return "bell.fill"
        case .eventReminder: return "calendar.badge.clock"
        }
    }

    var accentColor: Color {
        switch self {
        case .missedDose:    return Color.semanticError
        case .lowStock:      return Color.semanticWarning
        case .doseReminder:  return Color.brandPrimary
        case .eventReminder: return Color.semanticInfo
        }
    }

    var label: String {
        switch self {
        case .missedDose:    return "Missed Dose"
        case .lowStock:      return "Low Stock"
        case .doseReminder:  return "Dose Reminder"
        case .eventReminder: return "Event Reminder"
        }
    }
}

extension Date {
    var relativeTimeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
