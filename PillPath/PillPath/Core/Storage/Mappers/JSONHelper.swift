//
//  JSONHelper.swift
//  PillPath
//
//  Lightweight helpers for encoding/decoding simple arrays stored as JSON strings in CoreData.
//

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
}
