
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

final class FirebaseAuthService: AuthServiceProtocol {

    private(set) var currentUser: User?

    init() {
        if let fbUser = Auth.auth().currentUser, fbUser.isEmailVerified {
            currentUser = map(fbUser)
        }
    }


    func hasCachedSession() -> Bool {
        guard let fbUser = Auth.auth().currentUser else { return false }
        return fbUser.isEmailVerified
    }

    func restoreSession() async throws -> User {
        guard let fbUser = Auth.auth().currentUser, fbUser.isEmailVerified else {
            throw AuthError.sessionExpired
        }
        let user = map(fbUser)
        currentUser = user
        return user
    }


    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await result.user.reload()
            guard result.user.isEmailVerified else {
                throw AuthError.emailNotVerified
            }
            let user = map(result.user)
            currentUser = user
            return user
        } catch let error as AuthError {
            throw error
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            try await result.user.sendEmailVerification()
            return map(result.user, displayName: name)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }


    func resendVerificationEmail() async throws {
        guard let fbUser = Auth.auth().currentUser else { throw AuthError.sessionExpired }
        try await fbUser.sendEmailVerification()
    }

    func refreshEmailVerificationStatus() async throws -> Bool {
        guard let fbUser = Auth.auth().currentUser else { return false }
        try await fbUser.reload()
        if fbUser.isEmailVerified {
            let user = map(fbUser)
            currentUser = user
        }
        return fbUser.isEmailVerified
    }


    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }


    func sendPhoneVerification(phoneNumber: String) async throws -> String {
        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }

    func signInWithPhoneCredential(verificationID: String, code: String) async throws -> User {
        do {
            let credential = PhoneAuthProvider.provider()
                .credential(withVerificationID: verificationID, verificationCode: code)
            let result = try await Auth.auth().signIn(with: credential)
            let user = map(result.user)
            currentUser = user
            return user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }


    func signInWithGoogle(presenting: UIViewController) async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Firebase is not configured correctly.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.invalidCredentials
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let fbResult = try await Auth.auth().signIn(with: credential)
            let displayName = result.user.profile?.name ?? fbResult.user.displayName
            let user = map(fbResult.user, displayName: displayName)
            currentUser = user
            return user
        } catch let error as AuthError {
            throw error
        } catch let nsError as NSError where nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
            throw AuthError.unknown("Sign-in cancelled.")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }


    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
        throw AuthError.notImplemented
    }


    func signOut() {
        currentUser = nil
    }

    func isAuthenticated() -> Bool { currentUser != nil }


    private func map(_ fbUser: FirebaseAuth.User, displayName: String? = nil) -> User {
        User(
            id: UUID(uuidString: fbUser.uid) ?? UUID(),
            name: displayName ?? fbUser.displayName ?? fbUser.email?.components(separatedBy: "@").first ?? "User",
            email: fbUser.email ?? "",
            firebaseUID: fbUser.uid
        )
    }

    private func mapFirebaseError(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .wrongPassword, .invalidCredential, .userNotFound:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .userAlreadyExists
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        case .invalidEmail:
            return .invalidCredentials
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
