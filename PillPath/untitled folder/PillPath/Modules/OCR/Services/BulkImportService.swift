

import Foundation

protocol BulkImportServiceProtocol {
    func importMedications(_ items: [ScannedMedicationItem]) async throws -> [Medication]
}

final class BulkImportService: BulkImportServiceProtocol {

    private let medicationService: MedicationServiceProtocol
    private let scheduleService: ScheduleServiceProtocol
    private let doseTrackingService: DoseTrackingServiceProtocol

    init(
        medicationService: MedicationServiceProtocol? = nil,
        scheduleService: ScheduleServiceProtocol? = nil,
        doseTrackingService: DoseTrackingServiceProtocol? = nil
    ) {
        self.medicationService   = medicationService   ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
        self.scheduleService     = scheduleService     ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
        self.doseTrackingService = doseTrackingService ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
    }

    func importMedications(_ items: [ScannedMedicationItem]) async throws -> [Medication] {
        let accepted = items.filter { $0.action == .accepted }
        guard !accepted.isEmpty else { return [] }

       
        let existing = try medicationService.fetchAll()
        let existingNames = Set(existing.map { $0.name.lowercased() })

        var saved: [Medication] = []

        for item in accepted {
            let name = item.displayName
            guard !existingNames.contains(name.lowercased()) else { continue }

            let medication = Medication(
                name: name,
                genericName: item.fdaResult?.genericName,
                form: item.suggestedForm,
                dosageAmount: item.suggestedDosageAmount,
                dosageUnit: item.suggestedDosageUnit,
                instructions: item.fdaResult?.indications,
                sideEffects: item.fdaResult?.sideEffects ?? [],
                interactions: item.fdaResult?.interactions.map { [$0] } ?? []
            )

            try medicationService.save(medication)

            let schedule = MedicationSchedule(
                medicationId: medication.id,
                frequency: .daily,
                scheduleTimes: [.morning],
                mealTiming: .none,
                startDate: .now,
                isOngoing: true,
                doseReminders: true
            )

            try scheduleService.save(schedule, for: medication)

           
            try await doseTrackingService.generateUpcomingLogs(for: schedule, days: 7)

            saved.append(medication)
        }

        return saved
    }
}
