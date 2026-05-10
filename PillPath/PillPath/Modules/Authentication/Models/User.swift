

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var createdAt: Date
    var firebaseUID: String

    init(id: UUID = .init(), name: String, email: String, createdAt: Date = .now, firebaseUID: String = "") {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.firebaseUID = firebaseUID
    }
}
