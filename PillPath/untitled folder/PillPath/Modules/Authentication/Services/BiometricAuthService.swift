

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



protocol GoogleSSOServiceProtocol {
    func signIn() async throws -> User
    func signOut()
}


final class GoogleSSOService: GoogleSSOServiceProtocol {
    func signIn() async throws -> User {
        throw AuthError.notImplemented
    }

    func signOut() {
      
    }
}


