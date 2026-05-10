
import Foundation
import UIKit

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    func hasCachedSession() -> Bool
    func restoreSession() async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signUp(name: String, email: String, password: String) async throws -> User
    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User
    func signInWithGoogle(presenting: UIViewController) async throws -> User
    func signInWithPhoneCredential(verificationID: String, code: String) async throws -> User
    func sendPhoneVerification(phoneNumber: String) async throws -> String
    func sendPasswordReset(email: String) async throws
    func resendVerificationEmail() async throws
    func refreshEmailVerificationStatus() async throws -> Bool
    func signOut()
    func isAuthenticated() -> Bool
}

enum AuthError: LocalizedError {
    case notImplemented
    case invalidCredentials
    case biometryFailed
    case sessionExpired
    case userAlreadyExists
    case weakPassword
    case emailNotVerified
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:       return "This sign-in method is not available."
        case .invalidCredentials:   return "Invalid email or password. Please try again."
        case .biometryFailed:       return "Biometric authentication failed. Please sign in with your password."
        case .sessionExpired:       return "Your session has expired. Please sign in again."
        case .userAlreadyExists:    return "An account with this email already exists."
        case .weakPassword:         return "Password must be at least 8 characters."
        case .emailNotVerified:     return "Please verify your email address before signing in."
        case .networkError:         return "No internet connection. Please check your network and try again."
        case .unknown(let msg):     return msg
        }
    }
}
