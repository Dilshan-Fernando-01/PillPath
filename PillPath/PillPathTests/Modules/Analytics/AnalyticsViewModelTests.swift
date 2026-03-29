//
//  AnalyticsViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class AnalyticsViewModelTests: XCTestCase {

    func test_adherenceGrade_excellent() {
        let record = AdherenceRecord(
            id: .init(), medicationId: .init(), medicationName: "Test",
            period: DateInterval(start: .now, duration: 86400),
            totalDoses: 10, takenDoses: 10
        )
        XCTAssertEqual(record.grade, .excellent)
        XCTAssertEqual(record.adherencePercentage, 100.0)
    }

    func test_adherenceGrade_poor() {
        let record = AdherenceRecord(
            id: .init(), medicationId: .init(), medicationName: "Test",
            period: DateInterval(start: .now, duration: 86400),
            totalDoses: 10, takenDoses: 2
        )
        XCTAssertEqual(record.grade, .poor)
    }

    func test_adherencePercentage_zeroTotalDoses() {
        let record = AdherenceRecord(
            id: .init(), medicationId: .init(), medicationName: "Test",
            period: DateInterval(start: .now, duration: 86400),
            totalDoses: 0, takenDoses: 0
        )
        XCTAssertEqual(record.adherencePercentage, 0)
    }
}
