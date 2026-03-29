//
//  HomeViewModel.swift
//  PillPath — Home Module
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published state

    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var timeOfDayGroups: [TimeOfDayGroup] = []
    @Published var nextDose: DoseDisplayItem?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let scheduleService: ScheduleServiceProtocol
    private let doseTrackingService: DoseTrackingServiceProtocol
    private let medicationService: MedicationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        scheduleService: ScheduleServiceProtocol? = nil,
        doseTrackingService: DoseTrackingServiceProtocol? = nil,
        medicationService: MedicationServiceProtocol? = nil
    ) {
        self.scheduleService     = scheduleService     ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
        self.doseTrackingService = doseTrackingService ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
        self.medicationService   = medicationService   ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)

        // Re-load whenever selectedDate changes
        $selectedDate
            .removeDuplicates()
            .sink { [weak self] date in
                self?.loadDoses(for: date)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func loadDoses(for date: Date) {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Mark any pending past doses as missed before loading
            try doseTrackingService.detectAndMarkMissed()

            // 2. Fetch all active schedules
            let schedules = try scheduleService.fetchAll().filter(\.isActive)

            // 3. Fetch all medications (for display names/categories)
            let medications = try medicationService.fetchAll()
            let medMap = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })

            // 4. Fetch existing dose logs for this date
            let logs = try doseTrackingService.fetchLogs(on: date)
            let logMap = Dictionary(grouping: logs, by: { $0.scheduleId })

            // 5. Compute all scheduled dose times for this date
            let calendar = Calendar.current
            var items: [DoseDisplayItem] = []

            for schedule in schedules {
                guard let med = medMap[schedule.medicationId],
                      med.isActive else { continue }

                let doseTimes = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: 1)
                    .filter { calendar.isDate($0, inSameDayAs: date) }

                for doseTime in doseTimes {
                    let hour = calendar.component(.hour, from: doseTime)
                    let timeLabel = DoseTimeLabel.from(hour: hour)

                    // Match to an existing log (same schedule + same scheduled time within 1 min)
                    let matchedLog = logMap[schedule.id]?.first {
                        abs($0.scheduledAt.timeIntervalSince(doseTime)) < 60
                    }

                    let status: DoseStatus
                    if let log = matchedLog {
                        status = log.status
                    } else if Date.now > doseTime.addingTimeInterval(3600) && calendar.isDateInToday(date) {
                        status = .missed
                    } else {
                        status = .pending
                    }

                    let item = DoseDisplayItem(
                        id: matchedLog?.id ?? UUID(),
                        medicationId: med.id,
                        scheduleId: schedule.id,
                        medicationName: med.name,
                        dosageDisplay: med.dosageDisplay,
                        medicationCategory: med.instructions,
                        usageNote: med.notes,
                        scheduledAt: doseTime,
                        timeLabel: timeLabel,
                        mealTiming: schedule.mealTiming,
                        status: status,
                        logId: matchedLog?.id
                    )
                    items.append(item)
                }
            }

            // 6. Group items
            timeOfDayGroups = buildGroups(from: items)

            // 7. Find next upcoming dose (today only, pending/missed)
            if calendar.isDateInToday(date) {
                nextDose = items
                    .filter { $0.status == .pending && $0.scheduledAt > .now }
                    .sorted { $0.scheduledAt < $1.scheduledAt }
                    .first
            } else {
                nextDose = nil
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Mark actions

    func markTaken(_ item: DoseDisplayItem) {
        guard let logId = item.logId else {
            // No log yet — generate one first, then mark
            Task {
                do {
                    let schedule = try scheduleService.fetchAll()
                        .first(where: { $0.id == item.scheduleId })
                    if let schedule {
                        try doseTrackingService.generateUpcomingLogs(for: schedule, days: 1)
                    }
                    loadDoses(for: selectedDate)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        do {
            let log = DoseLog(
                id: logId,
                medicationId: item.medicationId,
                scheduleId: item.scheduleId,
                scheduledAt: item.scheduledAt,
                status: item.status
            )
            try doseTrackingService.markTaken(log, at: .now)
            loadDoses(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reverts a taken dose back to pending (undo accidental check-off).
    func undoTaken(_ item: DoseDisplayItem) {
        guard let logId = item.logId else { return }
        do {
            let log = DoseLog(
                id: logId,
                medicationId: item.medicationId,
                scheduleId: item.scheduleId,
                scheduledAt: item.scheduledAt,
                status: .taken
            )
            try doseTrackingService.markPending(log)
            loadDoses(for: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAllTaken() {
        let pending = timeOfDayGroups
            .flatMap(\.allItems)
            .filter { $0.status == .pending || $0.status == .missed }

        for item in pending { markTaken(item) }
    }

    // MARK: - Date navigation

    func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    // MARK: - Private: grouping

    private func buildGroups(from items: [DoseDisplayItem]) -> [TimeOfDayGroup] {
        let order: [DoseTimeLabel] = [.morning, .noon, .evening, .night]
        let mealOrder: [MealTiming] = [.before, .with, .after, .none]

        return order.map { timeLabel in
            let slotItems = items.filter { $0.timeLabel == timeLabel }
                                 .sorted { $0.scheduledAt < $1.scheduledAt }

            let mealGroups: [MealTimingGroup] = mealOrder.map { timing in
                MealTimingGroup(
                    id: timing,
                    timing: timing,
                    items: slotItems.filter { $0.mealTiming == timing }
                )
            }
            // Only include meal groups that have items OR show "none" as fallback
            let nonEmpty = mealGroups.filter { !$0.isEmpty }
            let displayed = nonEmpty.isEmpty ? mealGroups.filter { $0.timing == .none } : mealGroups

            return TimeOfDayGroup(
                id: timeLabel,
                label: timeLabel,
                mealGroups: displayed
            )
        }
    }
}

// MARK: - Time remaining helper

extension DoseDisplayItem {
    var timeRemainingDisplay: String {
        let diff = scheduledAt.timeIntervalSince(.now)
        guard diff > 0 else { return "Now" }
        let minutes = Int(diff / 60)
        if minutes < 60 { return "in \(minutes)m" }
        let hours = minutes / 60
        let mins  = minutes % 60
        return mins == 0 ? "in \(hours)h" : "in \(hours)h \(mins)m"
    }
}
