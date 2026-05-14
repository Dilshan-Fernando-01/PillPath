
import Foundation


struct MedicationSchedule: Identifiable, Codable {
    let id: UUID
    var medicationId: UUID
    var frequency: ScheduleFrequency
    var intervalHours: Int                  
    var specificDays: [Int]                 
    var customDates: [Date]                 
    var scheduleTimes: [ScheduleTime]
    var mealTiming: MealTiming
    var startDate: Date
    var endDate: Date?
    var isOngoing: Bool
    var doseReminders: Bool
    var notificationOffsetMinutes: NotificationOffset
    var isActive: Bool

    init(
        id: UUID = .init(),
        medicationId: UUID,
        frequency: ScheduleFrequency = .daily,
        intervalHours: Int = 8,
        specificDays: [Int] = [],
        customDates: [Date] = [],
        scheduleTimes: [ScheduleTime] = [],
        mealTiming: MealTiming = .none,
        startDate: Date = .now,
        endDate: Date? = nil,
        isOngoing: Bool = true,
        doseReminders: Bool = true,
        notificationOffsetMinutes: NotificationOffset = .atTime,
        isActive: Bool = true
    ) {
        self.id = id
        self.medicationId = medicationId
        self.frequency = frequency
        self.intervalHours = intervalHours
        self.specificDays = specificDays
        self.customDates = customDates
        self.scheduleTimes = scheduleTimes
        self.mealTiming = mealTiming
        self.startDate = startDate
        self.endDate = endDate
        self.isOngoing = isOngoing
        self.doseReminders = doseReminders
        self.notificationOffsetMinutes = notificationOffsetMinutes
        self.isActive = isActive
    }

   
    var frequencySummary: String {
        switch frequency {
        case .daily:
            let count = scheduleTimes.count
            return count == 1 ? "Once daily" : "\(count) times daily"
        case .everyXHours:
            return "Every \(intervalHours) hours"
        case .specificDays:
            return "Specific days"
        case .alternateDays:
            return "Alternate days"
        case .custom:
            return "Custom"
        }
    }
}



struct ScheduleTime: Codable, Identifiable, Hashable {
    var id: UUID = .init()
    var hour: Int
    var minute: Int
    var label: DoseTimeLabel

    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        return formatter.string(from: date)
    }

    static let morning = ScheduleTime(hour: 8,  minute: 0, label: .morning)
    static let noon    = ScheduleTime(hour: 12, minute: 0, label: .noon)
    static let evening = ScheduleTime(hour: 18, minute: 0, label: .evening)
    static let night   = ScheduleTime(hour: 21, minute: 0, label: .night)
}


struct DoseLog: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let scheduleId: UUID
    let scheduledAt: Date
    var takenAt: Date?
    var status: DoseStatus
    var notes: String?

    var wasTaken: Bool { status == .taken }
    var isMissed: Bool { status == .missed }
}



struct MedicalEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var provider: String?
    var medicationIds: [UUID]
    var date: Date
    var type: MedicalEventType
    var attachmentFilename: String?
    var attachmentDisplayName: String?
    let createdAt: Date

    init(
        id: UUID = .init(),
        title: String,
        notes: String? = nil,
        provider: String? = nil,
        medicationIds: [UUID] = [],
        date: Date,
        type: MedicalEventType = .note,
        attachmentFilename: String? = nil,
        attachmentDisplayName: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.provider = provider
        self.medicationIds = medicationIds
        self.date = date
        self.type = type
        self.attachmentFilename = attachmentFilename
        self.attachmentDisplayName = attachmentDisplayName
        self.createdAt = createdAt
    }
}



enum ScheduleFrequency: String, Codable, CaseIterable, Identifiable {
    case daily        = "daily"
    case everyXHours  = "everyXHours"
    case specificDays = "specificDays"
    case alternateDays = "alternateDays"
    case custom       = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:         return "Daily"
        case .everyXHours:   return "Every X hours"
        case .specificDays:  return "Specific days"
        case .alternateDays: return "Alternate days"
        case .custom:        return "Custom dates"
        }
    }

    var systemIcon: String {
        switch self {
        case .daily:         return "calendar"
        case .everyXHours:   return "clock"
        case .specificDays:  return "calendar.badge.checkmark"
        case .alternateDays: return "arrow.2.squarepath"
        case .custom:        return "calendar.badge.plus"
        }
    }
}

enum DoseTimeLabel: String, Codable, CaseIterable, Identifiable {
    case morning = "morning"
    case noon    = "noon"
    case evening = "evening"
    case night   = "night"
    case custom  = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .noon:    return "Noon"
        case .evening: return "Evening"
        case .night:   return "Night"
        case .custom:  return "Custom"
        }
    }

    var timeRange: String {
        switch self {
        case .morning: return "6 AM – 11 AM"
        case .noon:    return "11 AM – 4 PM"
        case .evening: return "4 PM – 9 PM"
        case .night:   return "9 PM – 6 AM"
        case .custom:  return "Specific / Repeating"
        }
    }

   
    var elderlyDisplayName: String {
        switch self {
        case .morning: return "Morning Medications"
        case .noon:    return "Afternoon Medications"
        case .evening: return "Evening Medications"
        case .night:   return "Night Medications"
        case .custom:  return "Scheduled Medications"
        }
    }

    var systemIcon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .noon:    return "sun.min.fill"
        case .evening: return "sunset.fill"
        case .night:   return "moon.fill"
        case .custom:  return "clock"
        }
    }
}

enum MealTiming: String, Codable, CaseIterable, Identifiable {
    case before = "before"
    case with   = "with"
    case after  = "after"
    case none   = "none"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .before: return "Before Meal"
        case .with:   return "With Meal"
        case .after:  return "After Meal"
        case .none:   return "No Preference"
        }
    }

    var shortName: String {
        switch self {
        case .before: return "Before"
        case .with:   return "With"
        case .after:  return "After"
        case .none:   return "Any time"
        }
    }

    var description: String {
        switch self {
        case .before: return "Take 30 minutes before eating"
        case .with:   return "Take during your meal"
        case .after:  return "Take 30 minutes after eating"
        case .none:   return "No specific meal requirement"
        }
    }

    var systemIcon: String {
        switch self {
        case .before: return "clock.arrow.circlepath"
        case .with:   return "fork.knife"
        case .after:  return "clock.fill"
        case .none:   return "circle.dashed"
        }
    }
}

enum DoseStatus: String, Codable {
    case pending = "pending"
    case taken   = "taken"
    case skipped = "skipped"
    case missed  = "missed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .taken:   return "Taken"
        case .skipped: return "Skipped"
        case .missed:  return "Missed"
        }
    }
}



extension DoseTimeLabel {
   
    static func from(hour: Int) -> DoseTimeLabel {
        switch hour {
        case 6..<12:  return .morning
        case 12..<17: return .noon
        case 17..<21: return .evening
        default:      return .night
        }
    }
}

enum MedicalEventType: String, Codable, CaseIterable, Identifiable {
    case doctorVisit = "doctorVisit"
    case test        = "test"
    case note        = "note"
    case other       = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doctorVisit: return "Doctor Visit"
        case .test:        return "Test / Lab"
        case .note:        return "Note"
        case .other:       return "Other"
        }
    }
}

enum NotificationOffset: Int, Codable, CaseIterable, Identifiable {
    case atTime       = 0
    case fifteenMins  = 15
    case oneHour      = 60
    case twoHours     = 120

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .atTime:      return "At time of dose"
        case .fifteenMins: return "15 mins before"
        case .oneHour:     return "1 hour before"
        case .twoHours:    return "2 hours before"
        }
    }
}
