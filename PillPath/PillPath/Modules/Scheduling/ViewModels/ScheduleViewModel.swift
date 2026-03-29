//
//  ScheduleViewModel.swift
//  PillPath — Scheduling Module
//

import Foundation
import Combine

@MainActor
final class ScheduleViewModel: ObservableObject {

    @Published var schedules: [MedicationSchedule] = []
    @Published var todaysDoses: [DoseLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let scheduleService: ScheduleServiceProtocol
    private let doseTrackingService: DoseTrackingServiceProtocol

    init(
        scheduleService: ScheduleServiceProtocol? = nil,
        doseTrackingService: DoseTrackingServiceProtocol? = nil
    ) {
        self.scheduleService     = scheduleService     ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
        self.doseTrackingService = doseTrackingService ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
    }

    // MARK: - Load

    func loadSchedules() {
        do {
            schedules = try scheduleService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTodaysDoses() {
        do {
            todaysDoses = try doseTrackingService.fetchLogs(on: .now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Add / Delete

    /// `medication` is required because ScheduleService links schedule → medication entity.
    func addSchedule(_ schedule: MedicationSchedule, for medication: Medication) {
        do {
            try scheduleService.save(schedule, for: medication)
            loadSchedules()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSchedule(_ schedule: MedicationSchedule) {
        do {
            try scheduleService.delete(schedule)
            schedules.removeAll { $0.id == schedule.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Dose Actions (delegated to DoseTrackingService)

    func markDoseTaken(_ log: DoseLog) {
        do {
            try doseTrackingService.markTaken(log, at: .now)
            loadTodaysDoses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markDoseSkipped(_ log: DoseLog) {
        do {
            try doseTrackingService.markSkipped(log)
            loadTodaysDoses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
