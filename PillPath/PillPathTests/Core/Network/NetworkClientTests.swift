//
//  NetworkClientTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

final class NetworkClientTests: XCTestCase {

    func test_openFDAEndpoint_searchDrug_buildsCorrectURL() throws {
        let endpoint = OpenFDAEndpoint.searchDrug(query: "aspirin", limit: 5)
        let request = try endpoint.urlRequest()
        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("api.fda.gov"))
        XCTAssertTrue(urlString.contains("aspirin"))
        XCTAssertTrue(urlString.contains("limit=5"))
    }

    func test_openFDAEndpoint_httpMethod_isGET() throws {
        let endpoint = OpenFDAEndpoint.searchDrug(query: "test", limit: 1)
        let request = try endpoint.urlRequest()
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_networkError_descriptions_areNotEmpty() {
        let errors: [NetworkError] = [
            .invalidURL, .noData, .offline,
            .serverError(statusCode: 500),
            .unknown(URLError(.badURL))
        ]
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                           "errorDescription should not be empty for \(error)")
        }
    }
}
