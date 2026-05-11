
import Foundation

struct AppBackup: Codable {
    let version: Int
    let exportedAt: Date
    let userId: String
    let medications: [MedicationBackup]
    let schedules: [ScheduleBackup]
    let scheduleTimes: [ScheduleTimeBackup]
    let doseLogs: [DoseLogBackup]
    let medicalEvents: [MedicalEventBackup]
}

struct MedicationBackup: Codable {
    let id: UUID
    let name: String
    let genericName: String?
    let displayName: String?
    let form: String
    let dosageAmount: Double
    let dosageUnit: String
    let instructions: String?
    let notes: String?
    let photoURL: String?
    let currentQuantity: Int32
    let lowQuantityAlert: Bool
    let lowQuantityThreshold: Int32
    let isActive: Bool
    let addedAt: Date
    let sideEffectsJSON: String?
    let interactionsJSON: String?
    let statusInfoJSON: String?

    init?(from entity: MedicationEntity) {
        guard let id = entity.id, let name = entity.name, let addedAt = entity.addedAt else { return nil }
        self.id = id
        self.name = name
        self.genericName = entity.genericName
        self.displayName = entity.displayName
        self.form = entity.form ?? "tablet"
        self.dosageAmount = entity.dosageAmount
        self.dosageUnit = entity.dosageUnit ?? "pills"
        self.instructions = entity.instructions
        self.notes = entity.notes
        self.photoURL = entity.photoURL
        self.currentQuantity = entity.currentQuantity
        self.lowQuantityAlert = entity.lowQuantityAlert
        self.lowQuantityThreshold = entity.lowQuantityThreshold
        self.isActive = entity.isActive
        self.addedAt = addedAt
        self.sideEffectsJSON = entity.sideEffectsJSON
        self.interactionsJSON = entity.interactionsJSON
        self.statusInfoJSON = entity.statusInfoJSON
    }
}

struct ScheduleBackup: Codable {
    let id: UUID
    let medicationId: UUID
    let frequency: String
    let intervalHours: Int32
    let specificDaysJSON: String?
    let customDatesJSON: String?
    let mealTiming: String
    let startDate: Date
    let endDate: Date?
    let isOngoing: Bool
    let doseReminders: Bool
    let notificationOffsetMinutes: Int32
    let isActive: Bool

    init?(from entity: ScheduleEntity) {
        guard let id = entity.id,
              let medId = entity.medication?.id,
              let startDate = entity.startDate else { return nil }
        self.id = id
        self.medicationId = medId
        self.frequency = entity.frequency ?? "daily"
        self.intervalHours = entity.intervalHours
        self.specificDaysJSON = entity.specificDaysJSON
        self.customDatesJSON = entity.customDatesJSON
        self.mealTiming = entity.mealTiming ?? "none"
        self.startDate = startDate
        self.endDate = entity.endDate
        self.isOngoing = entity.isOngoing
        self.doseReminders = entity.doseReminders
        self.notificationOffsetMinutes = entity.notificationOffsetMinutes
        self.isActive = entity.isActive
    }
}

struct ScheduleTimeBackup: Codable {
    let id: UUID
    let scheduleId: UUID
    let hour: Int32
    let minute: Int32
    let label: String

    init?(from entity: ScheduleTimeEntity) {
        guard let id = entity.id, let schedId = entity.schedule?.id else { return nil }
        self.id = id
        self.scheduleId = schedId
        self.hour = entity.hour
        self.minute = entity.minute
        self.label = entity.label ?? "custom"
    }
}

struct DoseLogBackup: Codable {
    let id: UUID
    let medicationId: UUID
    let scheduleId: UUID?
    let scheduledAt: Date
    let takenAt: Date?
    let status: String
    let notes: String?

    init?(from entity: DoseLogEntity) {
        guard let id = entity.id,
              let medId = entity.medication?.id,
              let scheduledAt = entity.scheduledAt else { return nil }
        self.id = id
        self.medicationId = medId
        self.scheduleId = entity.schedule?.id
        self.scheduledAt = scheduledAt
        self.takenAt = entity.takenAt
        self.status = entity.status ?? "pending"
        self.notes = entity.notes
    }
}

struct MedicalEventBackup: Codable {
    let id: UUID
    let title: String
    let eventDescription: String?
    let date: Date
    let type: String
    let createdAt: Date

    init?(from entity: MedicalEventEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let date = entity.date,
              let createdAt = entity.createdAt else { return nil }
        self.id = id
        self.title = title
        self.eventDescription = entity.eventDescription
        self.date = date
        self.type = entity.type ?? "note"
        self.createdAt = createdAt
    }
}
