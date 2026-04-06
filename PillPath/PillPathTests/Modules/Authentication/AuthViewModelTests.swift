//
//  AuthViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

@MainActor
final class AuthViewModelTests: XCTestCase {

    var sut: AuthViewModel!
    var mockAuth: MockAuthService!
    var mockBiometric: MockBiometricAuthService!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        mockBiometric = MockBiometricAuthService()
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
    }

    override func tearDown() {
        sut = nil
        mockAuth = nil
        mockBiometric = nil
        super.tearDown()
    }

    // MARK: - Init

    func test_init_isNotAuthenticated_byDefault() {
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    func test_init_restoresCurrentUser_whenServiceHasOne() {
        let user = User(name: "Dilshan", email: "d@test.com")
        mockAuth.currentUser = user
        let vm = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
        XCTAssertTrue(vm.isAuthenticated)
    }

    func test_init_setHasCachedSession_fromService() {
        mockAuth.cachedSessionExists = true
        let vm = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
        XCTAssertTrue(vm.hasCachedSession)
    }

    // MARK: - signIn

    func test_signIn_success_setsCurrentUser() async {
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertNotNil(sut.currentUser)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
    }

    func test_signIn_success_callsServiceWithCorrectEmail() async {
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertEqual(mockAuth.signInCallCount, 1)
        XCTAssertEqual(mockAuth.lastSignInEmail, "user@test.com")
    }

    func test_signIn_failure_setsErrorMessage() async {
        mockAuth.shouldThrowOnSignIn = true
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signIn_emptyEmail_setsValidationError_doesNotCallService() async {
        await sut.signIn(email: "", password: "password123")
        XCTAssertEqual(mockAuth.signInCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_signIn_emptyPassword_setsValidationError_doesNotCallService() async {
        await sut.signIn(email: "user@test.com", password: "")
        XCTAssertEqual(mockAuth.signInCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_signIn_clearsIsLoading_afterCompletion() async {
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - register

    func test_register_success_setsCurrentUser() async {
        await sut.register(name: "Dilshan", email: "d@test.com", password: "Password1!", confirmPassword: "Password1!")
        XCTAssertNotNil(sut.currentUser)
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_register_success_passesCorrectNameToService() async {
        await sut.register(name: "Dilshan", email: "d@test.com", password: "Password1!", confirmPassword: "Password1!")
        XCTAssertEqual(mockAuth.lastSignUpName, "Dilshan")
        XCTAssertEqual(mockAuth.signUpCallCount, 1)
    }

    func test_register_passwordMismatch_setsError_doesNotCallService() async {
        await sut.register(name: "Dilshan", email: "d@test.com", password: "Password1!", confirmPassword: "Different!")
        XCTAssertEqual(mockAuth.signUpCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_register_shortPassword_setsError_doesNotCallService() async {
        await sut.register(name: "Dilshan", email: "d@test.com", password: "abc", confirmPassword: "abc")
        XCTAssertEqual(mockAuth.signUpCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_register_emptyName_setsError_doesNotCallService() async {
        await sut.register(name: "", email: "d@test.com", password: "Password1!", confirmPassword: "Password1!")
        XCTAssertEqual(mockAuth.signUpCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_register_emptyEmail_setsError_doesNotCallService() async {
        await sut.register(name: "Dilshan", email: "", password: "Password1!", confirmPassword: "Password1!")
        XCTAssertEqual(mockAuth.signUpCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_register_serviceThrows_setsErrorMessage() async {
        mockAuth.shouldThrowOnSignUp = true
        await sut.register(name: "Dilshan", email: "d@test.com", password: "Password1!", confirmPassword: "Password1!")
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - signInWithBiometrics

    func test_signInWithBiometrics_success_setsCurrentUser() async {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        await sut.signInWithBiometrics()

        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(mockBiometric.authenticateCallCount, 1)
        XCTAssertEqual(mockAuth.restoreSessionCallCount, 1)
    }

    func test_signInWithBiometrics_biometryFails_setsError() async {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = true
        mockBiometric.authResult = false
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        await sut.signInWithBiometrics()

        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_signInWithBiometrics_biometryThrows_setsError() async {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = true
        mockBiometric.shouldThrow = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        await sut.signInWithBiometrics()

        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(mockAuth.restoreSessionCallCount, 0)
    }

    func test_signInWithBiometrics_noCachedSession_doesNotCallBiometric() async {
        mockAuth.cachedSessionExists = false
        mockBiometric.biometryAvailable = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        await sut.signInWithBiometrics()

        XCTAssertEqual(mockBiometric.authenticateCallCount, 0)
    }

    func test_signInWithBiometrics_biometryUnavailable_doesNotCallBiometric() async {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = false
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        await sut.signInWithBiometrics()

        XCTAssertEqual(mockBiometric.authenticateCallCount, 0)
    }

    // MARK: - isBiometryAvailable

    func test_isBiometryAvailable_trueWhenBothConditionsMet() {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
        XCTAssertTrue(sut.isBiometryAvailable)
    }

    func test_isBiometryAvailable_falseWhenNoCachedSession() {
        mockAuth.cachedSessionExists = false
        mockBiometric.biometryAvailable = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
        XCTAssertFalse(sut.isBiometryAvailable)
    }

    func test_isBiometryAvailable_falseWhenBiometryUnavailable() {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = false
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)
        XCTAssertFalse(sut.isBiometryAvailable)
    }

    // MARK: - signInWithApple

    func test_signInWithApple_success_setsCurrentUser() async {
        await sut.signInWithApple(idToken: "token", nonce: "nonce", fullName: nil)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(mockAuth.appleSignInCallCount, 1)
    }

    func test_signInWithApple_failure_setsErrorMessage() async {
        mockAuth.shouldThrowOnApple = true
        await sut.signInWithApple(idToken: "token", nonce: "nonce", fullName: nil)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - signInWithGoogle

    func test_signInWithGoogle_success_setsCurrentUser() async {
        await sut.signInWithGoogle()
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(mockAuth.googleSignInCallCount, 1)
    }

    func test_signInWithGoogle_failure_setsErrorMessage() async {
        mockAuth.shouldThrowOnGoogle = true
        await sut.signInWithGoogle()
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - signOut

    func test_signOut_clearsCurrentUser() async {
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertTrue(sut.isAuthenticated)

        sut.signOut()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertEqual(mockAuth.signOutCallCount, 1)
    }

    func test_signOut_resetsCachedSession() async {
        mockAuth.cachedSessionExists = true
        mockBiometric.biometryAvailable = true
        sut = AuthViewModel(authService: mockAuth, biometricService: mockBiometric)

        sut.signOut()

        XCTAssertFalse(sut.hasCachedSession)
    }

    func test_signOut_clearsErrorMessage() async {
        mockAuth.shouldThrowOnSignIn = true
        await sut.signIn(email: "user@test.com", password: "password123")
        XCTAssertNotNil(sut.errorMessage)

        sut.signOut()

        XCTAssertNil(sut.errorMessage)
    }
}
