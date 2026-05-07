//
//  NetworkError.swift
//  PillPath
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(statusCode: Int)
    case offline
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .noData:               return "No data received."
        case .decodingFailed(let e): return "Failed to decode response: \(e.localizedDescription)"
        case .serverError(let code): return "Server error (HTTP \(code))."
        case .offline:              return "No internet connection."
        case .unknown(let e):       return e.localizedDescription
        }
    }
}
