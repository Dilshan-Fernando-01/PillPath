//
//  MedicalEventMapperTests.swift
//  PillPathTests
//
//  Tests JSON pack/unpack in MedicalEventMapper and DoseHistoryItem out-of-window logic.
//

import XCTest
@testable import PillPath

final class MedicalEventMapperTests: XCTestCase {

    // MARK: - DoseHistoryItem out-of-window

    func test_outOfWindow_false_whenTakenInSameSlot() {
        let item = ActivityViewModel.DoseHistoryItem(
            id: UUID(),
            medicationName: "Aspirin",
            dosageDisplay: "1 Tablet",
            scheduledAt: makeDate(hour: 8),  // 8am → morning
            takenAt:      makeDate(hour: 9),  // 9am → still morning
            status: .taken,
            scheduledLabel: .morning,
            takenLabel: .morning
        )
        XCTAssertFalse(item.isOutOfWindow)
    }

    func test_outOfWindow_true_whenTakenInDifferentSlot() {
        let item = ActivityViewModel.DoseHistoryItem(
            id: UUID(),
            medicationName: "Ibuprofen",
            dosageDisplay: "1 Tablet",
            scheduledAt: makeDate(hour: 21), // 9pm → night
            takenAt:      makeDate(hour: 8),  // 8am → morning
            status: .taken,
            scheduledLabel: .night,
            takenLabel: .morning
        )
        XCTAssertTrue(item.isOutOfWindow)
    }

    func test_outOfWindow_false_whenStatusIsMissed() {
        let item = ActivityViewModel.DoseHistoryItem(
            id: UUID(),
            medicationName: "Metformin",
            dosageDisplay: "500mg",
            scheduledAt: makeDate(hour: 21),
            takenAt: nil,
            status: .missed,
            scheduledLabel: .night,
            takenLabel: nil
        )
        XCTAssertFalse(item.isOutOfWindow)
    }

    func test_outOfWindow_false_whenNoTakenAt() {
        let item = ActivityViewModel.DoseHistoryItem(
            id: UUID(),
            medicationName: "Metformin",
            dosageDisplay: "500mg",
            scheduledAt: makeDate(hour: 8),
            takenAt: nil,
            status: .taken,
            scheduledLabel: .morning,
            takenLabel: nil
        )
        XCTAssertFalse(item.isOutOfWindow)
    }

    // MARK: - DoseTimeLabel window boundaries

    func test_doseTimeLabel_from_hour_morning() {
        XCTAssertEqual(DoseTimeLabel.from(hour: 6),  .morning)
        XCTAssertEqual(DoseTimeLabel.from(hour: 10), .morning)
        XCTAssertEqual(DoseTimeLabel.from(hour: 11), .morning)
    }

    func test_doseTimeLabel_from_hour_noon() {
        XCTAssertEqual(DoseTimeLabel.from(hour: 12), .noon)
        XCTAssertEqual(DoseTimeLabel.from(hour: 14), .noon)
        XCTAssertEqual(DoseTimeLabel.from(hour: 16), .noon)
    }

    func test_doseTimeLabel_from_hour_evening() {
        XCTAssertEqual(DoseTimeLabel.from(hour: 17), .evening)
        XCTAssertEqual(DoseTimeLabel.from(hour: 19), .evening)
        XCTAssertEqual(DoseTimeLabel.from(hour: 20), .evening)
    }

    func test_doseTimeLabel_from_hour_night() {
        XCTAssertEqual(DoseTimeLabel.from(hour: 21), .night)
        XCTAssertEqual(DoseTimeLabel.from(hour: 0),  .night)
        XCTAssertEqual(DoseTimeLabel.from(hour: 5),  .night)
    }

    // MARK: - MedicalEvent notes rename (regression)

    func test_medicalEvent_notes_field_exists() {
        let event = MedicalEvent(
            title: "Test Event",
            notes: "Take only if pain persists",
            date: .now
        )
        XCTAssertEqual(event.notes, "Take only if pain persists")
    }

    func test_medicalEvent_notes_defaults_to_nil() {
        let event = MedicalEvent(title: "No Notes Event", date: .now)
        XCTAssertNil(event.notes)
    }

    // MARK: - DoseDisplayItem usageNote

    func test_doseDisplayItem_usageNote_propagates() {
        let item = DoseDisplayItem(
            id: UUID(), medicationId: UUID(), scheduleId: UUID(),
            medicationName: "Lisinopril", dosageDisplay: "1 Tablet",
            medicationCategory: "Blood Pressure",
            usageNote: "Only take if you have chest pain",
            scheduledAt: .now, timeLabel: .morning,
            mealTiming: .none, status: .pending
        )
        XCTAssertEqual(item.usageNote, "Only take if you have chest pain")
    }

    func test_doseDisplayItem_usageNote_can_be_nil() {
        let item = DoseDisplayItem(
            id: UUID(), medicationId: UUID(), scheduleId: UUID(),
            medicationName: "Aspirin", dosageDisplay: "1 Tablet",
            medicationCategory: nil, usageNote: nil,
            scheduledAt: .now, timeLabel: .morning,
            mealTiming: .none, status: .pending
        )
        XCTAssertNil(item.usageNote)
    }

    // MARK: - Private helpers

    private func makeDate(hour: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = hour
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? .now
    }
}
