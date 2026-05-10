
import SwiftUI
import Combine

struct EmailVerificationPendingView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var resendCooldown = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                Spacer().frame(height: AppSpacing.lg)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 100, height: 100)
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.brandPrimary)
                }

                // Title
                VStack(spacing: AppSpacing.sm) {
                    Text("Check Your Email")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)

                    Text("We sent a verification link to")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)

                    Text(email)
                        .font(AppFont.headline())
                        .foregroundStyle(Color.brandPrimary)
                        .multilineTextAlignment(.center)
                }

                // Instructions card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    InstructionRow(number: "1", text: "Open the email from PillPath")
                    InstructionRow(number: "2", text: "Click the verification link")
                    InstructionRow(number: "3", text: "Return here and tap Verified below")
                }
                .padding(AppSpacing.lg)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // Error
                if let error = authViewModel.errorMessage {
                    AuthErrorBanner(message: error)
                }

                // Check verified button
                PrimaryButton(
                    title: "I've Verified My Email",
                    icon: "checkmark.circle",
                    isLoading: authViewModel.isLoading
                ) {
                    Task { await authViewModel.checkEmailVerified() }
                }

                // Resend button
                Button {
                    Task {
                        await authViewModel.resendVerificationEmail()
                        resendCooldown = 60
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                        Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend verification email")
                            .font(AppFont.subheadline())
                    }
                    .foregroundStyle(resendCooldown > 0 ? Color.textDisabled : Color.brandPrimary)
                }
                .disabled(resendCooldown > 0 || authViewModel.isLoading)

                // Back to login
                Button("Back to Sign In") {
                    authViewModel.errorMessage = nil
                    dismiss()
                }
                .font(AppFont.subheadline())
                .foregroundStyle(Color.textSecondary)
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            if resendCooldown > 0 { resendCooldown -= 1 }
        }
        .onAppear {
            authViewModel.errorMessage = nil
        }
    }
}

private struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}
