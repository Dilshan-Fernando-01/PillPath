//
//  AuthViewModel.swift
//  PillPath — Authentication Module
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? DIContainer.shared.resolve(AuthServiceProtocol.self)
        self.currentUser = self.authService.currentUser
    }

    var isAuthenticated: Bool { currentUser != nil }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        authService.signOut()
        currentUser = nil
    }
}
