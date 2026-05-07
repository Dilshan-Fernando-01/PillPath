

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
        return loadCachedUser() != nil && UserDefaults.standard.bool(forKey: "pp_session_active")
    }

    func restoreSession() async throws -> User {
        guard let user = loadCachedUser() else {
            throw AuthError.sessionExpired
        }
        currentUser = user
        return user
    }



    func signIn(email: String, password: String) async throws -> User {
        let creds = loadCredentials()
        guard let stored = creds[email.lowercased()] else {
            throw AuthError.invalidCredentials
        }
        guard stored["password"] == password else {
            throw AuthError.invalidCredentials
        }
        let name = stored["name"] ?? email.components(separatedBy: "@").first ?? "User"
        let user = User(name: name, email: email.lowercased())
        currentUser = user
        persistUser(user)
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        var creds = loadCredentials()
        if creds[email.lowercased()] != nil {
            throw AuthError.userAlreadyExists
        }
        creds[email.lowercased()] = ["name": name, "password": password]
        saveCredentials(creds)
        let user = User(name: name, email: email.lowercased())
        currentUser = user
        persistUser(user)
        return user
    }

    

    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
    
        throw AuthError.notImplemented
    }

  

    func signInWithGoogle() async throws -> User {

        throw AuthError.notImplemented
    }



    func signOut() {
      
        currentUser = nil
        UserDefaults.standard.set(false, forKey: "pp_session_active")
     
    }

    func isAuthenticated() -> Bool { currentUser != nil }



    private func loadCredentials() -> [String: [String: String]] {
        guard let data = UserDefaults.standard.data(forKey: "pp_credentials"),
              let creds = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return [:]
        }
        return creds
    }

    private func saveCredentials(_ creds: [String: [String: String]]) {
        if let data = try? JSONEncoder().encode(creds) {
            UserDefaults.standard.set(data, forKey: "pp_credentials")
        }
    }

    private func persistUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "pp_cachedUser")
        }
        UserDefaults.standard.set(true, forKey: "pp_session_active")
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
