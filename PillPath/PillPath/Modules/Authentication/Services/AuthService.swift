

import Foundation



protocol AuthServiceProtocol {
    var currentUser: User? { get }
    func hasCachedSession() -> Bool
    func restoreSession() async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signUp(name: String, email: String, password: String) async throws -> User
    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User
    func signInWithGoogle() async throws -> User
    func signOut()
    func isAuthenticated() -> Bool
}

final class AuthService: AuthServiceProtocol {

    private(set) var currentUser: User?

   

    func hasCachedSession() -> Bool {
        return loadCachedUser() != nil
    }

    func restoreSession() async throws -> User {
        guard let user = loadCachedUser() else {
            throw AuthError.sessionExpired
        }
        currentUser = user
        return user
    }



    func signIn(email: String, password: String) async throws -> User {
       
        let user = User(name: email.components(separatedBy: "@").first ?? "User", email: email)
        currentUser = user
        persistUser(user)
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        // TODO (Firebase):
        //   let result = try await Auth.auth().createUser(withEmail: email, password: password)
        //   let changeRequest = result.user.createProfileChangeRequest()
        //   changeRequest.displayName = name
        //   try await changeRequest.commitChanges()
        //   return User(id: UUID(), name: name, email: email)
        let user = User(name: name, email: email)
        currentUser = user
        persistUser(user)
        return user
    }

    // MARK: Apple Sign In

    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
        // TODO (Firebase):
        //   let credential = OAuthProvider.appleCredential(withIDToken: idToken,
        //                                                   rawNonce: nonce,
        //                                                   fullName: fullName)
        //   let result = try await Auth.auth().signIn(with: credential)
        //   let name = [fullName?.givenName, fullName?.familyName]
        //       .compactMap { $0 }.joined(separator: " ")
        //   return User(id: UUID(), name: name.isEmpty ? "Apple User" : name,
        //               email: result.user.email ?? "")
        throw AuthError.notImplemented
    }

    // MARK: Google Sign In

    func signInWithGoogle() async throws -> User {
        // TODO (Firebase + GoogleSignIn SDK):
        //   1. Add GoogleSignIn package: https://github.com/google/GoogleSignIn-iOS
        //   2. guard let clientID = FirebaseApp.app()?.options.clientID else { throw AuthError.notImplemented }
        //   3. let config = GIDConfiguration(clientID: clientID)
        //   4. GIDSignIn.sharedInstance.configuration = config
        //   5. let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        //   6. guard let idToken = result.user.idToken?.tokenString else { throw AuthError.notImplemented }
        //   7. let credential = GoogleAuthProvider.credential(withIDToken: idToken,
        //                                                      accessToken: result.user.accessToken.tokenString)
        //   8. let firebaseResult = try await Auth.auth().signIn(with: credential)
        //   9. return User(id: UUID(), name: firebaseResult.user.displayName ?? "",
        //                  email: firebaseResult.user.email ?? "")
        throw AuthError.notImplemented
    }

    // MARK: Sign Out

    func signOut() {
        // TODO (Firebase): try? Auth.auth().signOut()
        currentUser = nil
        clearPersistedUser()
    }

    func isAuthenticated() -> Bool { currentUser != nil }

    // MARK: - Session persistence (stub — replace with Keychain in production)
    //
    // Firebase automatically manages token persistence.
    // These methods are only used by the local stub above.

    private func persistUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "pp_cachedUser")
        }
    }

    private func loadCachedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "pp_cachedUser") else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    private func clearPersistedUser() {
        UserDefaults.standard.removeObject(forKey: "pp_cachedUser")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notImplemented
    case invalidCredentials
    case biometryFailed
    case sessionExpired
    case userAlreadyExists
    case weakPassword

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This sign-in method requires Firebase setup. See setup guide."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .biometryFailed:
            return "Biometric authentication failed. Please sign in with your password."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 8 characters."
        }
    }
}
