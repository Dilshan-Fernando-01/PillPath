

import Foundation

enum JSONHelper {

    static func encodeStringArray(_ array: [String]) -> String? {
        guard !array.isEmpty else { return nil }
        return try? String(data: JSONEncoder().encode(array), encoding: .utf8)
    }

    static func decodeStringArray(_ json: String?) -> [String] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    static func encodeIntArray(_ array: [Int]) -> String? {
        guard !array.isEmpty else { return nil }
        return try? String(data: JSONEncoder().encode(array), encoding: .utf8)
    }

    static func decodeIntArray(_ json: String) -> [Int]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([Int].self, from: data)
    }

    static func encodeDateArray(_ dates: [Date]) -> String? {
        guard !dates.isEmpty else { return nil }
        let timestamps = dates.map { $0.timeIntervalSince1970 }
        return try? String(data: JSONEncoder().encode(timestamps), encoding: .utf8)
    }

    static func decodeDateArray(_ json: String?) -> [Date] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        let timestamps = (try? JSONDecoder().decode([Double].self, from: data)) ?? []
        return timestamps.map { Date(timeIntervalSince1970: $0) }
    }
}
