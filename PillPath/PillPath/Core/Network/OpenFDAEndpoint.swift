//
//  OpenFDAEndpoint.swift
//  PillPath
//
//  openFDA API endpoints.
//  Docs: https://open.fda.gov/apis/drug/
//

import Foundation

enum OpenFDAEndpoint: APIEndpoint {

    /// Search drugs by brand name or generic name.
    case searchDrug(query: String, limit: Int)
    /// Get drug label information by drug name.
    case drugLabel(name: String)
    /// Get drug adverse events.
    case adverseEvents(drugName: String, limit: Int)

    var baseURL: String { "https://api.fda.gov" }

    var path: String {
        switch self {
        case .searchDrug, .drugLabel: return "/drug/label.json"
        case .adverseEvents:          return "/drug/event.json"
        }
    }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchDrug(let query, let limit):
            return [
                URLQueryItem(name: "search", value: "openfda.brand_name:\"\(query)\""),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        case .drugLabel(let name):
            return [
                URLQueryItem(name: "search", value: "openfda.generic_name:\"\(name)\""),
                URLQueryItem(name: "limit", value: "1")
            ]
        case .adverseEvents(let drugName, let limit):
            return [
                URLQueryItem(name: "search", value: "patient.drug.medicinalproduct:\"\(drugName)\""),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }
}
