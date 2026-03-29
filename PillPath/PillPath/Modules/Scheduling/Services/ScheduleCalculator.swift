//
//  ScheduleCalculator.swift
//  PillPath — Scheduling Module
//
//  Pure business logic — no CoreData, no network.
//  Given a MedicationSchedule, computes upcoming dose times.
//  Fully unit-testable without any dependencies.
//

import Foundation

enum ScheduleCalculator {

    // MARK: - Upcoming Dose Times

    /// Returns all scheduled dose Date values within the next `days` days.
    static func upcomingDoseTimes(for schedule: MedicationSchedule, days: Int = 7) -> [Date] {
        guard schedule.isActive else { return [] }
        let calendar = Calendar.current
        let now = Date.now
        let end = calendar.date(byAdding: .day, value: days, to: now) ?? now

        switch schedule.frequency {
        case .daily:
            return dailyDoses(schedule: schedule, from: now, to: end, calendar: calendar)

        case .everyXHours:
            return intervalDoses(schedule: schedule, from: now, to: end, calendar: calendar)

        case .specificDays:
            return specificDayDoses(schedule: schedule, from: now, to: end, calendar: calendar)

        case .alternateDays:
            return alternateDayDoses(schedule: schedule, from: now, to: end, calendar: calendar)

        case .custom:
            // Custom is handled via manual dose times only
            return dailyDoses(schedule: schedule, from: now, to: end, calendar: calendar)
        }
    }

    // MARK: - Today's Doses

    static func todaysDoses(for schedule: MedicationSchedule) -> [Date] {
        upcomingDoseTimes(for: schedule, days: 1)
            .filter { Calendar.current.isDateInToday($0) }
    }

    // MARK: - Adherence Calculation

    /// Returns adherence percentage (0–100) given a list of dose logs.
    static func adherencePercentage(logs: [DoseLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let relevant = logs.filter { $0.status != .pending }
        guard !relevant.isEmpty else { return 0 }
        let taken = relevant.filter { $0.status == .taken }.count
        return Double(taken) / Double(relevant.count) * 100
    }

    /// Detects whether a dose is missed: scheduled time has passed by more than the grace period.
    static func isMissed(_ log: DoseLog, gracePeriodMinutes: Int = 60) -> Bool {
        guard log.status == .pending else { return false }
        let cutoff = log.scheduledAt.addingTimeInterval(TimeInterval(gracePeriodMinutes * 60))
        return Date.now > cutoff
    }

    // MARK: - Private Generators

    private static func dailyDoses(
        schedule: MedicationSchedule,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        var current = calendar.startOfDay(for: start)
        while current <= end {
            guard isWithinScheduleRange(current, schedule: schedule, calendar: calendar) else {
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? end
                continue
            }
            for time in schedule.scheduleTimes {
                if let doseDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: current) {
                    if doseDate > start && doseDate <= end {
                        results.append(doseDate)
                    }
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? end
        }
        return results.sorted()
    }

    private static func intervalDoses(
        schedule: MedicationSchedule,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        var current = schedule.startDate > start ? schedule.startDate : start
        let interval = TimeInterval(schedule.intervalHours * 3600)
        while current <= end {
            if isWithinScheduleRange(current, schedule: schedule, calendar: calendar) {
                results.append(current)
            }
            current = current.addingTimeInterval(interval)
        }
        return results
    }

    private static func specificDayDoses(
        schedule: MedicationSchedule,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        var current = calendar.startOfDay(for: start)
        while current <= end {
            let weekday = calendar.component(.weekday, from: current) - 1  // 0=Sun
            if schedule.specificDays.contains(weekday) &&
               isWithinScheduleRange(current, schedule: schedule, calendar: calendar) {
                for time in schedule.scheduleTimes {
                    if let doseDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: current) {
                        if doseDate > start && doseDate <= end {
                            results.append(doseDate)
                        }
                    }
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? end
        }
        return results.sorted()
    }

    private static func alternateDayDoses(
        schedule: MedicationSchedule,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: schedule.startDate),
                                                     to: calendar.startOfDay(for: start)).day ?? 0
        var current = calendar.startOfDay(for: start)
        var dayOffset = daysSinceStart

        while current <= end {
            if dayOffset % 2 == 0 && isWithinScheduleRange(current, schedule: schedule, calendar: calendar) {
                for time in schedule.scheduleTimes {
                    if let doseDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: current) {
                        if doseDate > start && doseDate <= end {
                            results.append(doseDate)
                        }
                    }
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? end
            dayOffset += 1
        }
        return results.sorted()
    }

    private static func isWithinScheduleRange(_ date: Date, schedule: MedicationSchedule, calendar: Calendar) -> Bool {
        let startOfDate = calendar.startOfDay(for: date)
        let startOfSchedule = calendar.startOfDay(for: schedule.startDate)
        guard startOfDate >= startOfSchedule else { return false }
        if !schedule.isOngoing, let endDate = schedule.endDate {
            return startOfDate <= calendar.startOfDay(for: endDate)
        }
        return true
    }
}
