import Foundation
@testable import PillPath

final class MockAuthService: AuthServiceProtocol {


    var currentUser: User?
    var cachedSessionExists = false
    var userToReturn: User = User(name: "Test User", email: "test@example.com")

    var shouldThrowOnSignIn        = false
    var shouldThrowOnSignUp        = false
    var shouldThrowOnRestoreSession = false
    var shouldThrowOnApple         = false
    var shouldThrowOnGoogle        = false


    var signInCallCount          = 0
    var signUpCallCount          = 0
    var restoreSessionCallCount  = 0
    var signOutCallCount         = 0
    var appleSignInCallCount     = 0
    var googleSignInCallCount    = 0
    var lastSignInEmail: String?
    var lastSignUpName: String?

  

    func hasCachedSession() -> Bool { cachedSessionExists }

    func restoreSession() async throws -> User {
        restoreSessionCallCount += 1
        if shouldThrowOnRestoreSession { throw TestError.forced }
        currentUser = userToReturn
        return userToReturn
    }

    func signIn(email: String, password: String) async throws -> User {
        signInCallCount += 1
        lastSignInEmail = email
        if shouldThrowOnSignIn { throw TestError.forced }
        currentUser = userToReturn
        return userToReturn
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        signUpCallCount += 1
        lastSignUpName = name
        if shouldThrowOnSignUp { throw TestError.forced }
        let user = User(name: name, email: email)
        currentUser = user
        return user
    }

    func signInWithAppleCredential(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> User {
        appleSignInCallCount += 1
        if shouldThrowOnApple { throw TestError.forced }
        currentUser = userToReturn
        return userToReturn
    }

    func signInWithGoogle() async throws -> User {
        googleSignInCallCount += 1
        if shouldThrowOnGoogle { throw TestError.forced }
        currentUser = userToReturn
        return userToReturn
    }

    func signOut() {
        signOutCallCount += 1
        currentUser = nil
    }

    func isAuthenticated() -> Bool { currentUser != nil }
}
