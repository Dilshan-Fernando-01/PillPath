//
//  NetworkClient.swift
//  PillPath
//
//  Generic async/await HTTP client.
//  Usage: let result = try await NetworkClient.shared.request(OpenFDAEndpoint.search(...))
//

import Foundation

protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {

    static let shared = NetworkClient()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try endpoint.urlRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
}
