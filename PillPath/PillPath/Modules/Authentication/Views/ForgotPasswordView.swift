
import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    Spacer().frame(height: AppSpacing.lg)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimaryLight)
                            .frame(width: 100, height: 100)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.brandPrimary)
                    }

                    // Title
                    VStack(spacing: AppSpacing.sm) {
                        Text("Reset Password")
                            .font(AppFont.largeTitle())
                            .foregroundStyle(Color.textPrimary)

                        Text("Enter your email and we'll send you a link to reset your password.")
                            .font(AppFont.subheadline())
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Success state
                    if authViewModel.passwordResetSent {
                        VStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.semanticSuccess.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.semanticSuccess)
                            }

                            Text("Email Sent")
                                .font(AppFont.headline())
                                .foregroundStyle(Color.textPrimary)

                            Text("Check your inbox for a reset link. It may take a minute to arrive.")
                                .font(AppFont.subheadline())
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)

                            PrimaryButton(title: "Done") {
                                authViewModel.passwordResetSent = false
                                authViewModel.errorMessage = nil
                                dismiss()
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    } else {
                        // Email field
                        AuthTextField(
                            placeholder: "Email address",
                            icon: "envelope",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        // Error
                        if let error = authViewModel.errorMessage {
                            AuthErrorBanner(message: error)
                        }

                        // Send button
                        PrimaryButton(
                            title: "Send Reset Link",
                            icon: "paperplane",
                            isLoading: authViewModel.isLoading,
                            isDisabled: email.isEmpty
                        ) {
                            Task { await authViewModel.sendPasswordReset(email: email) }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        authViewModel.errorMessage = nil
                        authViewModel.passwordResetSent = false
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
            .onDisappear {
                authViewModel.errorMessage = nil
                authViewModel.passwordResetSent = false
            }
        }
    }
}
