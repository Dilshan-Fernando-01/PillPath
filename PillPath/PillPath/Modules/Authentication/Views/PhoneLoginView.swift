
import SwiftUI

struct PhoneLoginView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var countryCode = "+1"
    @State private var phoneNumber = ""
    @State private var navigateToOTP = false

    private var formattedNumber: String { "\(countryCode)\(phoneNumber.filter(\.isNumber))" }

    private let countryCodes = ["+1", "+44", "+61", "+64", "+91", "+94", "+65", "+60", "+81", "+82"]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                Spacer().frame(height: AppSpacing.lg)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 100, height: 100)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.brandPrimary)
                }

                // Title
                VStack(spacing: AppSpacing.sm) {
                    Text("Phone Sign In")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)

                    Text("Enter your phone number and we'll send you a one-time code.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Phone input
                HStack(spacing: AppSpacing.sm) {
                    // Country code picker
                    Menu {
                        ForEach(countryCodes, id: \.self) { code in
                            Button(code) { countryCode = code }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(countryCode)
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
                    }

                    // Number field
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "phone")
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 20)
                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
                }

                // Simulator note
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.semanticInfo)
                        Text("Testing on simulator? Use +1 650-555-0000 with code 123456.")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.semanticInfo.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                // Error
                if let error = authViewModel.errorMessage {
                    AuthErrorBanner(message: error)
                }

                // Send OTP
                PrimaryButton(
                    title: "Send Code",
                    icon: "arrow.right",
                    isLoading: authViewModel.isLoading,
                    isDisabled: phoneNumber.filter(\.isNumber).count < 6
                ) {
                    Task {
                        await authViewModel.sendPhoneOTP(phoneNumber: formattedNumber)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Phone Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToOTP) {
            PhoneOTPView(phoneNumber: formattedNumber)
        }
        .onChange(of: authViewModel.phoneVerificationSent) { _, sent in
            if sent {
                authViewModel.phoneVerificationSent = false
                navigateToOTP = true
            }
        }
        .onDisappear {
            authViewModel.errorMessage = nil
        }
    }
}
