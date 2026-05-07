

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
        
        let user = User(name: name, email: email)
        currentUser = user
        persistUser(user)
        return user
    }



    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
       
        throw AuthError.notImplemented
    }

    // MARK: Google Sign In

    func signInWithGoogle() async throws -> User {
      
        throw AuthError.notImplemented
    }

   

    func signOut() {
       
        currentUser = nil
        clearPersistedUser()
    }

    func isAuthenticated() -> Bool { currentUser != nil }



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
