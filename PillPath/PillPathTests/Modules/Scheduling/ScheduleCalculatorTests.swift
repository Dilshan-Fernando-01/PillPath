//
//  ScheduleCalculatorTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

final class ScheduleCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeDailySchedule(times: [ScheduleTime] = [.morning, .evening]) -> MedicationSchedule {
        MedicationSchedule(
            medicationId: UUID(),
            frequency: .daily,
            scheduleTimes: times,
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        )
    }

    // MARK: - upcomingDoseTimes

    func test_daily_schedule_generates_doses_for_each_day() {
        let schedule = makeDailySchedule(times: [.morning, .evening])
        let doses = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: 3)
        // 2 times × 3 days = 6 doses
        XCTAssertEqual(doses.count, 6)
    }

    func test_inactive_schedule_returns_empty() {
        var schedule = makeDailySchedule()
        schedule.isActive = false
        let doses = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: 7)
        XCTAssertTrue(doses.isEmpty)
    }

    func test_doses_are_sorted_ascending() {
        let schedule = makeDailySchedule(times: [.night, .morning])
        let doses = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: 2)
        for i in 0..<(doses.count - 1) {
            XCTAssertLessThanOrEqual(doses[i], doses[i + 1])
        }
    }

    func test_todays_doses_only_returns_today() {
        let schedule = makeDailySchedule(times: [.morning, .evening])
        let today = ScheduleCalculator.todaysDoses(for: schedule)
        today.forEach {
            XCTAssertTrue(Calendar.current.isDateInToday($0))
        }
    }

    // MARK: - adherencePercentage

    func test_adherence_100_percent() {
        let logs = makeLogs(taken: 5, missed: 0, skipped: 0)
        XCTAssertEqual(ScheduleCalculator.adherencePercentage(logs: logs), 100.0)
    }

    func test_adherence_50_percent() {
        let logs = makeLogs(taken: 5, missed: 5, skipped: 0)
        XCTAssertEqual(ScheduleCalculator.adherencePercentage(logs: logs), 50.0)
    }

    func test_adherence_ignores_pending() {
        let logs = makeLogs(taken: 4, missed: 0, skipped: 0, pending: 10)
        XCTAssertEqual(ScheduleCalculator.adherencePercentage(logs: logs), 100.0)
    }

    func test_adherence_empty_returns_zero() {
        XCTAssertEqual(ScheduleCalculator.adherencePercentage(logs: []), 0.0)
    }

    // MARK: - isMissed

    func test_missed_past_grace_period() {
        let log = DoseLog(
            id: UUID(),
            medicationId: UUID(),
            scheduleId: UUID(),
            scheduledAt: Date.now.addingTimeInterval(-7200),  // 2 hours ago
            status: .pending
        )
        XCTAssertTrue(ScheduleCalculator.isMissed(log, gracePeriodMinutes: 60))
    }

    func test_not_missed_within_grace_period() {
        let log = DoseLog(
            id: UUID(),
            medicationId: UUID(),
            scheduleId: UUID(),
            scheduledAt: Date.now.addingTimeInterval(-1800),  // 30 mins ago
            status: .pending
        )
        XCTAssertFalse(ScheduleCalculator.isMissed(log, gracePeriodMinutes: 60))
    }

    func test_taken_log_is_not_missed() {
        let log = DoseLog(
            id: UUID(),
            medicationId: UUID(),
            scheduleId: UUID(),
            scheduledAt: Date.now.addingTimeInterval(-7200),
            status: .taken
        )
        XCTAssertFalse(ScheduleCalculator.isMissed(log))
    }

    // MARK: - Private

    private func makeLogs(taken: Int, missed: Int, skipped: Int, pending: Int = 0) -> [DoseLog] {
        let medId = UUID()
        let schedId = UUID()
        func makeLog(_ status: DoseStatus) -> DoseLog {
            DoseLog(id: UUID(), medicationId: medId, scheduleId: schedId, scheduledAt: .now, status: status)
        }
        return Array(repeating: makeLog(.taken), count: taken)
            + Array(repeating: makeLog(.missed), count: missed)
            + Array(repeating: makeLog(.skipped), count: skipped)
            + Array(repeating: makeLog(.pending), count: pending)
    }
}
