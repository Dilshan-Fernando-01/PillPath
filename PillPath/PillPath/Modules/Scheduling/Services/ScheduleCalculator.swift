

import Foundation

enum ScheduleCalculator {

    static func upcomingDoseTimes(for schedule: MedicationSchedule, days: Int = 7, from startOverride: Date = .now) -> [Date] {
        guard schedule.isActive else { return [] }
        let calendar = Calendar.current
        let start = startOverride
        let end = calendar.date(byAdding: .day, value: days, to: start) ?? start

        switch schedule.frequency {
        case .daily:
            return dailyDoses(schedule: schedule, from: start, to: end, calendar: calendar)

        case .everyXHours:
            return intervalDoses(schedule: schedule, from: start, to: end, calendar: calendar)

        case .specificDays:
            return specificDayDoses(schedule: schedule, from: start, to: end, calendar: calendar)

        case .alternateDays:
            return alternateDayDoses(schedule: schedule, from: start, to: end, calendar: calendar)

        case .custom:
            return customDateDoses(schedule: schedule, from: start, to: end, calendar: calendar)
        }
    }

  

    static func todaysDoses(for schedule: MedicationSchedule) -> [Date] {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return upcomingDoseTimes(for: schedule, days: 1, from: startOfToday)
            .filter { Calendar.current.isDateInToday($0) }
    }

   static func adherencePercentage(logs: [DoseLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let relevant = logs.filter { $0.status != .pending }
        guard !relevant.isEmpty else { return 0 }
        let taken = relevant.filter { $0.status == .taken }.count
        return Double(taken) / Double(relevant.count) * 100
    }

   static func isMissed(_ log: DoseLog, gracePeriodMinutes: Int = 60) -> Bool {
        guard log.status == .pending else { return false }
        let cutoff = log.scheduledAt.addingTimeInterval(TimeInterval(gracePeriodMinutes * 60))
        return Date.now > cutoff
    }

   

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
        guard schedule.intervalHours > 0 else { return [] }
        var results: [Date] = []
        let interval = TimeInterval(schedule.intervalHours * 60)
        var current = schedule.startDate
        if current < start {
            let elapsed = start.timeIntervalSince(current)
            let periods = floor(elapsed / interval)
            current = current.addingTimeInterval(periods * interval)
        }
        while current <= end {
            if current > start && isWithinScheduleRange(current, schedule: schedule, calendar: calendar) {
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
            let weekday = calendar.component(.weekday, from: current) - 1 
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

    private static func customDateDoses(
        schedule: MedicationSchedule,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        var results: [Date] = []
        for customDate in schedule.customDates {
            let dayStart = calendar.startOfDay(for: customDate)
            guard dayStart >= calendar.startOfDay(for: start) && dayStart <= end else { continue }
            let times = schedule.scheduleTimes.isEmpty ? [ScheduleTime.morning] : schedule.scheduleTimes
            for time in times {
                if let doseDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: customDate) {
                    if doseDate > start && doseDate <= end {
                        results.append(doseDate)
                    }
                }
            }
        }
        return results.sorted()
    }

    private static func isWithinScheduleRange(_ date: Date, schedule: MedicationSchedule, calendar: Calendar) -> Bool {
        let startOfDate = calendar.startOfDay(for: date)
        guard startOfDate >= calendar.startOfDay(for: schedule.startDate) else { return false }
        if let endDate = schedule.endDate {
            return startOfDate <= calendar.startOfDay(for: endDate)
        }
        return true
    }
}
