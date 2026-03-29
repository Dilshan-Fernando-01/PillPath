//
//  MedicationModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

final class MedicationModelTests: XCTestCase {

    func test_dosageDisplay_wholeNumber() {
        let med = Medication(name: "Aspirin", dosageAmount: 1, dosageUnit: .pills)
        XCTAssertEqual(med.dosageDisplay, "1 pills")
    }

    func test_dosageDisplay_decimal() {
        let med = Medication(name: "Aspirin", dosageAmount: 0.5, dosageUnit: .pills)
        XCTAssertEqual(med.dosageDisplay, "0.5 pills")
    }

    func test_medicationForm_systemIcon_notEmpty() {
        MedicationForm.allCases.forEach { form in
            XCTAssertFalse(form.systemIcon.isEmpty, "\(form) icon should not be empty")
        }
    }

    func test_scheduleFrequency_displayName_notEmpty() {
        ScheduleFrequency.allCases.forEach { freq in
            XCTAssertFalse(freq.displayName.isEmpty)
        }
    }

    func test_mealTiming_description_notEmpty() {
        MealTiming.allCases.forEach { timing in
            XCTAssertFalse(timing.description.isEmpty)
        }
    }

    func test_adherenceGrade_thresholds() {
        let excellent = AdherenceRecord(id: .init(), medicationId: .init(), medicationName: "A",
                                        period: .init(start: .now, duration: 86400), totalDoses: 10, takenDoses: 10)
        XCTAssertEqual(excellent.grade, .excellent)

        let good = AdherenceRecord(id: .init(), medicationId: .init(), medicationName: "B",
                                   period: .init(start: .now, duration: 86400), totalDoses: 10, takenDoses: 8)
        XCTAssertEqual(good.grade, .good)

        let fair = AdherenceRecord(id: .init(), medicationId: .init(), medicationName: "C",
                                   period: .init(start: .now, duration: 86400), totalDoses: 10, takenDoses: 6)
        XCTAssertEqual(fair.grade, .fair)

        let poor = AdherenceRecord(id: .init(), medicationId: .init(), medicationName: "D",
                                   period: .init(start: .now, duration: 86400), totalDoses: 10, takenDoses: 3)
        XCTAssertEqual(poor.grade, .poor)
    }
}
