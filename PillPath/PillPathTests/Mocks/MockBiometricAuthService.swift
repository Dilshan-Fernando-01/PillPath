
import Foundation
import LocalAuthentication
@testable import PillPath

final class MockBiometricAuthService: BiometricAuthServiceProtocol {


    var biometryType: LABiometryType = .faceID
    var biometryAvailable = true
    var shouldThrow       = false
    var authResult        = true


    var authenticateCallCount = 0
    var lastReason: String?


    func isBiometryAvailable() -> Bool { biometryAvailable }

    func authenticate(reason: String) async throws -> Bool {
        authenticateCallCount += 1
        lastReason = reason
        if shouldThrow { throw AuthError.biometryFailed }
        return authResult
    }
}
