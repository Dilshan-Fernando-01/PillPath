//
//  AuthService.swift
//  PillPath — Authentication Module
//
//  TODO: Implement real auth (local biometrics / Firebase / custom backend).
//

import Foundation

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    func signIn(email: String, password: String) async throws -> User
    func signOut()
    func isAuthenticated() -> Bool
}

final class AuthService: AuthServiceProtocol {

    private(set) var currentUser: User?

    func signIn(email: String, password: String) async throws -> User {
        // Placeholder: replace with real auth logic
        let user = User(name: "Test User", email: email)
        currentUser = user
        return user
    }

    func signOut() {
        currentUser = nil
    }

    func isAuthenticated() -> Bool {
        currentUser != nil
    }
}
