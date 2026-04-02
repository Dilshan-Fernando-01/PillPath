

import Foundation
import Combine
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasCachedSession: Bool = false

    private let authService: AuthServiceProtocol
    private let biometricService: BiometricAuthServiceProtocol

    init(
        authService: AuthServiceProtocol? = nil,
        biometricService: BiometricAuthServiceProtocol? = nil
    ) {
        self.authService = authService ?? DIContainer.shared.resolve(AuthServiceProtocol.self)
        self.biometricService = biometricService ?? DIContainer.shared.resolve(BiometricAuthServiceProtocol.self)
        self.currentUser = self.authService.currentUser
        self.hasCachedSession = self.authService.hasCachedSession()
    }

    var isAuthenticated: Bool { currentUser != nil }

    /// True only when the device has biometrics AND a prior session can be restored.
    var isBiometryAvailable: Bool {
        biometricService.isBiometryAvailable() && hasCachedSession
    }

    var biometryType: LABiometryType { biometricService.biometryType }


    func signIn(email: String, password: String) async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register(name: String, email: String, password: String, confirmPassword: String) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signUp(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func signInWithBiometrics() async {
        guard isBiometryAvailable else { return }
        isLoading = true
        errorMessage = nil
        do {
            let success = try await biometricService.authenticate(reason: "Sign in to PillPath")
            if success {
                currentUser = try await authService.restoreSession()
            } else {
                errorMessage = AuthError.biometryFailed.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }



    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signInWithAppleCredential(
                idToken: idToken,
                nonce: nonce,
                fullName: fullName
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }



    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }



    func signOut() {
        authService.signOut()
        currentUser = nil
        hasCachedSession = false
        errorMessage = nil
    }
}
