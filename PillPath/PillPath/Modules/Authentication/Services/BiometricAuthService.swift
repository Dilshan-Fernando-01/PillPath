

import Foundation
import LocalAuthentication

protocol BiometricAuthServiceProtocol {
    var biometryType: LABiometryType { get }
    func authenticate(reason: String) async throws -> Bool
    func isBiometryAvailable() -> Bool
}

final class BiometricAuthService: BiometricAuthServiceProtocol {


    var biometryType: LABiometryType {
        let ctx = LAContext()
        var error: NSError?
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return ctx.biometryType
    }

    func isBiometryAvailable() -> Bool {
        let ctx = LAContext()
        var error: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        return try await ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}




