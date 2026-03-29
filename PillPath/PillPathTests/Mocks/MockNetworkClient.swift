//
//  MockNetworkClient.swift
//  PillPathTests
//

import Foundation
@testable import PillPath

final class MockNetworkClient: NetworkClientProtocol {

    var responseData: Data?
    var shouldThrow = false
    var requestCallCount = 0

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        requestCallCount += 1
        if shouldThrow { throw NetworkError.noData }
        guard let data = responseData else { throw NetworkError.noData }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
