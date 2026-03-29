//
//  MockScheduleService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockScheduleService: ScheduleServiceProtocol {

    var schedules: [MedicationSchedule] = []
    var shouldThrow = false

    func fetchAll() throws -> [MedicationSchedule] {
        if shouldThrow { throw TestError.forced }
        return schedules
    }

    func fetch(for medicationId: UUID) throws -> [MedicationSchedule] {
        if shouldThrow { throw TestError.forced }
        return schedules.filter { $0.medicationId == medicationId }
    }

    func save(_ schedule: MedicationSchedule, for medication: Medication) throws {
        if shouldThrow { throw TestError.forced }
        schedules.removeAll { $0.id == schedule.id }
        schedules.append(schedule)
    }

    func delete(_ schedule: MedicationSchedule) throws {
        if shouldThrow { throw TestError.forced }
        schedules.removeAll { $0.id == schedule.id }
    }

    func setActive(_ isActive: Bool, scheduleId: UUID) throws {
        if shouldThrow { throw TestError.forced }
        if let idx = schedules.firstIndex(where: { $0.id == scheduleId }) {
            schedules[idx].isActive = isActive
        }
    }
}
