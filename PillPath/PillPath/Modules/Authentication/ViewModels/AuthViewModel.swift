
import Foundation
import Combine
import LocalAuthentication
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var currentUser: User? {
        didSet { AppSession.shared.currentUserId = currentUser?.firebaseUID ?? "" }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasCachedSession: Bool = false
    @Published var isLocked: Bool = false

    @Published var registrationSuccess = false
    @Published var pendingVerificationEmail: String = ""
    @Published var emailJustVerified: Bool = false

    @Published var phoneVerificationID: String = ""
    @Published var phoneVerificationSent = false

    @Published var passwordResetSent = false

    private let authService: AuthServiceProtocol
    private let biometricService: BiometricAuthServiceProtocol

    init(
        authService: AuthServiceProtocol? = nil,
        biometricService: BiometricAuthServiceProtocol? = nil
    ) {
        self.authService = authService ?? DIContainer.shared.resolve(AuthServiceProtocol.self)
        self.biometricService = biometricService ?? DIContainer.shared.resolve(BiometricAuthServiceProtocol.self)
        let hasSession = self.authService.hasCachedSession()
        let biometricEnabled = UserDefaults.standard.bool(forKey: "pp_biometric_lock")
        if hasSession && biometricEnabled {
            self.isLocked = true
        } else {
            self.currentUser = self.authService.currentUser
            AppSession.shared.currentUserId = self.authService.currentUser?.firebaseUID ?? ""
        }
        self.hasCachedSession = hasSession
    }

    var isAuthenticated: Bool { currentUser != nil }

    var isBiometryAvailable: Bool {
        biometricService.isBiometryAvailable()
            && authService.hasCachedSession()
            && UserDefaults.standard.bool(forKey: "pp_biometric_lock")
    }

    var biometryType: LABiometryType { biometricService.biometryType }


    func signIn(email: String, password: String) async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        emailJustVerified = false
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch let authErr as AuthError where authErr == .emailNotVerified {
            pendingVerificationEmail = email
            errorMessage = authErr.localizedDescription
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
            _ = try await authService.signUp(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            pendingVerificationEmail = email.trimmingCharacters(in: .whitespaces)
            registrationSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func resendVerificationEmail() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.resendVerificationEmail()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkEmailVerified() async {
        isLoading = true
        errorMessage = nil
        do {
            let verified = try await authService.refreshEmailVerificationStatus()
            if verified {
                authService.signOut()
                currentUser = nil
                emailJustVerified = true
            } else {
                errorMessage = "Email not verified yet. Please check your inbox and click the link."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func sendPasswordReset(email: String) async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.sendPasswordReset(email: email.trimmingCharacters(in: .whitespaces))
            passwordResetSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func sendPhoneOTP(phoneNumber: String) async {
        guard !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a phone number."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            phoneVerificationID = try await authService.sendPhoneVerification(phoneNumber: phoneNumber)
            phoneVerificationSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func verifyPhoneOTP(code: String) async {
        guard !phoneVerificationID.isEmpty else {
            errorMessage = "Session expired. Please request a new code."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signInWithPhoneCredential(
                verificationID: phoneVerificationID,
                code: code
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func signInWithGoogle() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else {
            errorMessage = "Unable to present Google sign-in."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await authService.signInWithGoogle(presenting: rootVC)
        } catch let authErr as AuthError where authErr == .unknown("Sign-in cancelled.") {
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


    func signInWithBiometrics() async {
        guard isBiometryAvailable && !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let success = try await biometricService.authenticate(reason: "Sign in to PillPath")
            if success {
                currentUser = try await authService.restoreSession()
                isLocked = false
            } else {
                errorMessage = AuthError.biometryFailed.localizedDescription
            }
        } catch let laError as LAError
            where laError.code == .userCancel
               || laError.code == .userFallback
               || laError.code == .appCancel
               || laError.code == .systemCancel {
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    func signOut() {
        authService.signOut()
        currentUser = nil
        isLocked = false
        hasCachedSession = false
        errorMessage = nil
        registrationSuccess = false
        pendingVerificationEmail = ""
        emailJustVerified = false
        phoneVerificationID = ""
        phoneVerificationSent = false
        passwordResetSent = false
    }
}

extension AuthError: Equatable {
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
