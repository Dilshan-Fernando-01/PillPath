//
//  EmergencyContact.swift
//  PillPath — Home / Settings Module
//

import Foundation

struct EmergencyContact: Codable, Equatable {
    var name: String
    var phoneNumber: String           // digits only, e.g. "0771234567"

    /// tel:// URL used with UIApplication.open
    var callURL: URL? {
        let digits = phoneNumber.filter(\.isNumber)
        return URL(string: "tel://\(digits)")
    }
}
