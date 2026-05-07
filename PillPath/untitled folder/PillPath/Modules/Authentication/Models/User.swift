//
//  User.swift
//  PillPath — Authentication Module
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var createdAt: Date

    init(id: UUID = .init(), name: String, email: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
    }
}
