//
//  BiometricAuthService.swift
//  PillPath — Authentication Module
//
//  Stub — Face ID / Touch ID authentication.
//  Full implementation in Phase 3.
//

import Foundation
import LocalAuthentication

protocol BiometricAuthServiceProtocol {
    var biometryType: LABiometryType { get }
    func authenticate(reason: String) async throws -> Bool
    func isBiometryAvailable() -> Bool
}

final class BiometricAuthService: BiometricAuthServiceProtocol {

    private let context = LAContext()

    var biometryType: LABiometryType {
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    func isBiometryAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        guard isBiometryAvailable() else { return false }
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}

// MARK: - Google SSO Stub

protocol GoogleSSOServiceProtocol {
    func signIn() async throws -> User
    func signOut()
}

/// Placeholder — integrate GoogleSignIn SDK in Phase 3.
final class GoogleSSOService: GoogleSSOServiceProtocol {
    func signIn() async throws -> User {
        throw AuthError.notImplemented
    }

    func signOut() {
        // TODO: Call GIDSignIn.sharedInstance.signOut()
    }
}

enum AuthError: LocalizedError {
    case notImplemented
    case invalidCredentials
    case biometryFailed

    var errorDescription: String? {
        switch self {
        case .notImplemented:     return "This sign-in method is not yet available."
        case .invalidCredentials: return "Invalid email or password."
        case .biometryFailed:     return "Biometric authentication failed."
        }
    }
}
