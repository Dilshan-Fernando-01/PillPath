

import Foundation

struct EmergencyContact: Codable, Equatable {
    var name: String
    var phoneNumber: String          


    var callURL: URL? {
        let digits = phoneNumber.filter(\.isNumber)
        return URL(string: "tel://\(digits)")
    }
}
