//
//  MockDoseTrackingService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockDoseTrackingService: DoseTrackingServiceProtocol {

    var logs: [DoseLog] = []
    var shouldThrow = false

    var markTakenCallCount  = 0
    var markSkippedCallCount = 0
    var detectMissedCallCount = 0

    func fetchLogs(medicationId: UUID) throws -> [DoseLog] {
        if shouldThrow { throw TestError.forced }
        return logs.filter { $0.medicationId == medicationId }
    }

    func fetchLogs(scheduleId: UUID) throws -> [DoseLog] {
        if shouldThrow { throw TestError.forced }
        return logs.filter { $0.scheduleId == scheduleId }
    }

    func fetchLogs(on date: Date) throws -> [DoseLog] {
        if shouldThrow { throw TestError.forced }
        return logs.filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: date) }
    }

    func markTaken(_ log: DoseLog, at time: Date) throws {
        markTakenCallCount += 1
        if shouldThrow { throw TestError.forced }
        if let idx = logs.firstIndex(where: { $0.id == log.id }) {
            logs[idx] = DoseLog(
                id: log.id, medicationId: log.medicationId,
                scheduleId: log.scheduleId, scheduledAt: log.scheduledAt,
                takenAt: time, status: .taken
            )
        }
    }

    func markPending(_ log: DoseLog) throws {
        if shouldThrow { throw TestError.forced }
        if let idx = logs.firstIndex(where: { $0.id == log.id }) {
            logs[idx] = DoseLog(
                id: log.id, medicationId: log.medicationId,
                scheduleId: log.scheduleId, scheduledAt: log.scheduledAt,
                status: .pending
            )
        }
    }

    func markSkipped(_ log: DoseLog) throws {
        markSkippedCallCount += 1
        if shouldThrow { throw TestError.forced }
    }

    func detectAndMarkMissed() throws {
        detectMissedCallCount += 1
        if shouldThrow { throw TestError.forced }
    }

    func generateUpcomingLogs(for schedule: MedicationSchedule, days: Int) throws {
        if shouldThrow { throw TestError.forced }
    }
}
