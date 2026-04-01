//
//  LoginView.swift
//  PillPath — Authentication Module
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import LocalAuthentication

struct LoginView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var currentNonce = ""
    @State private var navigateToRegister = false
    @State private var showBiometricError = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                
                VStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimaryLight)
                            .frame(width: 80, height: 80)
                        Image(systemName: "pills.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.brandPrimary)
                    }

                    Text("Welcome Back")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)

                    Text("Sign in to continue your medication journey")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.lg)

               
                if authViewModel.isBiometryAvailable {
                    BiometricSignInCard(
                        biometryType: authViewModel.biometryType,
                        isLoading: authViewModel.isLoading
                    ) {
                        Task { await authViewModel.signInWithBiometrics() }
                    }
                }

                
                VStack(spacing: AppSpacing.md) {
                    AuthTextField(
                        placeholder: "Email address",
                        icon: "envelope",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    AuthSecureField(
                        placeholder: "Password",
                        text: $password,
                        showPassword: $showPassword
                    )

                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // TODO: Navigate to password reset
                        }
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.brandPrimary)
                    }
                }

               
                if let error = authViewModel.errorMessage {
                    AuthErrorBanner(message: error)
                }

               
                PrimaryButton(
                    title: "Sign In",
                    isLoading: authViewModel.isLoading,
                    isDisabled: email.isEmpty || password.isEmpty
                ) {
                    Task { await authViewModel.signIn(email: email, password: password) }
                }

               
                DividerWithLabel(label: "or continue with")

                
                VStack(spacing: AppSpacing.md) {
                    // Apple Sign In (native button)
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            guard
                                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                                let tokenData = credential.identityToken,
                                let idToken = String(data: tokenData, encoding: .utf8)
                            else { return }
                            Task {
                                await authViewModel.signInWithApple(
                                    idToken: idToken,
                                    nonce: currentNonce,
                                    fullName: credential.fullName
                                )
                            }
                        case .failure(let error):
                            authViewModel.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(height: 56)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1.5))

    
                    GoogleSignInButton {
                        Task { await authViewModel.signInWithGoogle() }
                    }
                }

               
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                    Button("Register") {
                        navigateToRegister = true
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToRegister) {
            RegisterView()
        }
        .task {
          
            if authViewModel.isBiometryAvailable {
                await authViewModel.signInWithBiometrics()
            }
        }
    }
}

// MARK: - Biometric Sign-In Card

private struct BiometricSignInCard: View {
    let biometryType: LABiometryType
    let isLoading: Bool
    let action: () -> Void

    private var iconName: String {
        biometryType == .faceID ? "faceid" : "touchid"
    }
    private var label: String {
        biometryType == .faceID ? "Sign in with Face ID" : "Sign in with Touch ID"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 48, height: 48)
                    if isLoading {
                        ProgressView().progressViewStyle(.circular).tint(Color.brandPrimary)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFont.headline())
                        .foregroundStyle(Color.textPrimary)
                    Text("Instant secure access")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textDisabled)
                    .font(.system(size: 14))
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1.5)
            )
            .appCardShadow()
        }
        .disabled(isLoading)
    }
}


private struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text("Sign in with Google")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appSurface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1.5))
        }
    }
}


struct AuthTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "lock")
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .font(AppFont.body())
            .foregroundStyle(Color.textPrimary)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.semanticError)
            Text(message)
                .font(AppFont.subheadline())
                .foregroundStyle(Color.semanticError)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.semanticError.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

struct DividerWithLabel: View {
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 1)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
                .fixedSize()
            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 1)
        }
    }
}


private extension LoginView {
    func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess { fatalError("Unable to generate nonce.") }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
