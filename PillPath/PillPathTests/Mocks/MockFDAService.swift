//
//  MockFDAService.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockFDAService: FDAServiceProtocol {

    var stubbedResults: [MedicationSearchResult] = []
    var searchCallCount = 0
    var lastQuery: String?
    var shouldThrow = false

    func search(query: String, limit: Int) async throws -> [MedicationSearchResult] {
        searchCallCount += 1
        lastQuery = query
        if shouldThrow { throw TestError.forced }
        return stubbedResults
    }

    func details(for name: String) async throws -> MedicationSearchResult? {
        if shouldThrow { throw TestError.forced }
        return stubbedResults.first
    }
}
