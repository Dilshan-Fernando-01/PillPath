//
//  RegisterView.swift
//  PillPath — Authentication Module
//

import SwiftUI

struct RegisterView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        agreedToTerms
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                VStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimaryLight)
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.brandPrimary)
                    }

                    Text("Create Account")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)

                    Text("Start managing your medications today")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.lg)

              
                VStack(spacing: AppSpacing.md) {
                    AuthTextField(
                        placeholder: "Full name",
                        icon: "person",
                        text: $fullName,
                        textContentType: .name
                    )

                    AuthTextField(
                        placeholder: "Email address",
                        icon: "envelope",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        AuthSecureField(
                            placeholder: "Password",
                            text: $password,
                            showPassword: $showPassword
                        )
                        Text("Minimum 8 characters")
                            .font(AppFont.caption())
                            .foregroundStyle(
                                password.isEmpty ? Color.textSecondary
                                : password.count >= 8 ? Color.semanticSuccess
                                : Color.semanticError
                            )
                            .padding(.leading, AppSpacing.xs)
                    }

                    AuthSecureField(
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        showPassword: $showConfirmPassword
                    )

                    if !confirmPassword.isEmpty && password != confirmPassword {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.semanticError)
                                .font(.caption)
                            Text("Passwords do not match")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.semanticError)
                            Spacer()
                        }
                        .padding(.leading, AppSpacing.xs)
                    }
                }

               
                if !password.isEmpty {
                    PasswordStrengthIndicator(password: password)
                }

               
                Button {
                    agreedToTerms.toggle()
                } label: {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(agreedToTerms ? Color.brandPrimary : Color.appSurface)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(agreedToTerms ? Color.brandPrimary : Color.appBorder, lineWidth: 1.5)
                                )
                            if agreedToTerms {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text("I agree to the ")
                            .foregroundStyle(Color.textSecondary)
                        + Text("Terms of Service")
                            .foregroundStyle(Color.brandPrimary)
                            .underline()
                        + Text(" and ")
                            .foregroundStyle(Color.textSecondary)
                        + Text("Privacy Policy")
                            .foregroundStyle(Color.brandPrimary)
                            .underline()
                    }
                    .font(AppFont.subheadline())
                    .multilineTextAlignment(.leading)
                }

               
                if let error = authViewModel.errorMessage {
                    AuthErrorBanner(message: error)
                }

                
                PrimaryButton(
                    title: "Create Account",
                    icon: "arrow.right",
                    isLoading: authViewModel.isLoading,
                    isDisabled: !isFormValid
                ) {
                    Task {
                        await authViewModel.register(
                            name: fullName,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword
                        )
                    }
                }

                
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                    Button("Sign In") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            authViewModel.errorMessage = nil
        }
    }
}


private struct PasswordStrengthIndicator: View {
    let password: String

    private enum Strength: Int {
        case weak = 1, fair = 2, good = 3, strong = 4

        var label: String {
            switch self {
            case .weak:   return "Weak"
            case .fair:   return "Fair"
            case .good:   return "Good"
            case .strong: return "Strong"
            }
        }
        var color: Color {
            switch self {
            case .weak:   return .semanticError
            case .fair:   return .semanticWarning
            case .good:   return .semanticInfo
            case .strong: return .semanticSuccess
            }
        }
    }

    private var strength: Strength {
        var score = 0
        if password.count >= 8  { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9!@#$%^&*]", options: .regularExpression) != nil { score += 1 }
        return Strength(rawValue: max(1, score)) ?? .weak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(1...4, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= strength.rawValue ? strength.color : Color.appBorder)
                        .frame(height: 4)
                }
            }
            Text("Password strength: \(strength.label)")
                .font(AppFont.caption())
                .foregroundStyle(strength.color)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
