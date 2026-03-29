//
//  AnalyticsService.swift
//  PillPath — Analytics Module
//

import Foundation
import CoreData

protocol AnalyticsServiceProtocol {
    func adherenceRecords(for period: DateInterval) throws -> [AdherenceRecord]
    func overallAdherence(for period: DateInterval) throws -> Double
    func streakDays() throws -> Int
}

final class AnalyticsService: AnalyticsServiceProtocol {

    private let coreData: CoreDataStack

    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
    }

    // MARK: - Adherence per Medication

    func adherenceRecords(for period: DateInterval) throws -> [AdherenceRecord] {
        // Fetch all medications
        let medRequest = MedicationEntity.fetchRequest()
        medRequest.predicate = NSPredicate(format: "isActive == YES")
        let medications = try coreData.viewContext.fetch(medRequest)

        return medications.compactMap { medEntity -> AdherenceRecord? in
            guard let medId = medEntity.id, let medName = medEntity.name else { return nil }

            let logRequest = DoseLogEntity.fetchRequest()
            logRequest.predicate = NSPredicate(
                format: "medication.id == %@ AND scheduledAt >= %@ AND scheduledAt <= %@",
                medId as CVarArg, period.start as CVarArg, period.end as CVarArg
            )
            guard let logs = try? coreData.viewContext.fetch(logRequest) else { return nil }

            // Only count non-pending logs
            let relevant = logs.filter { $0.status != DoseStatus.pending.rawValue }
            guard !relevant.isEmpty else { return nil }

            let taken = relevant.filter { $0.status == DoseStatus.taken.rawValue }.count

            return AdherenceRecord(
                id: UUID(),
                medicationId: medId,
                medicationName: medName,
                period: period,
                totalDoses: relevant.count,
                takenDoses: taken
            )
        }
    }

    // MARK: - Overall Adherence

    func overallAdherence(for period: DateInterval) throws -> Double {
        let records = try adherenceRecords(for: period)
        guard !records.isEmpty else { return 0 }
        return records.map(\.adherencePercentage).reduce(0, +) / Double(records.count)
    }

    // MARK: - Streak (consecutive days with ≥ 1 dose taken)

    func streakDays() throws -> Int {
        let calendar = Calendar.current
        var streak = 0
        var date = calendar.startOfDay(for: .now)

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let request = DoseLogEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "status == %@ AND scheduledAt >= %@ AND scheduledAt < %@",
                DoseStatus.taken.rawValue, date as CVarArg, nextDay as CVarArg
            )
            let count = (try? coreData.viewContext.count(for: request)) ?? 0
            if count > 0 {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return streak
    }
}
