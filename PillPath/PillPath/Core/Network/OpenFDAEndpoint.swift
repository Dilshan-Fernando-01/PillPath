

import Foundation

enum OpenFDAEndpoint: APIEndpoint {

  
    case searchDrug(query: String, limit: Int)
   
    case drugLabel(name: String)
  
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
