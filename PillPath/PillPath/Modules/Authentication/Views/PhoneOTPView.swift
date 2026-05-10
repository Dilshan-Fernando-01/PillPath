
import SwiftUI
import Combine

struct PhoneOTPView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    let phoneNumber: String

    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var resendCooldown = 60
    @FocusState private var focusedIndex: Int?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var fullCode: String { otpDigits.joined() }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                Spacer().frame(height: AppSpacing.lg)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 100, height: 100)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.brandPrimary)
                }

                // Title
                VStack(spacing: AppSpacing.sm) {
                    Text("Enter Code")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)

                    Text("We sent a 6-digit code to")
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)

                    Text(phoneNumber)
                        .font(AppFont.headline())
                        .foregroundStyle(Color.brandPrimary)
                }

                // OTP digit boxes
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitBox(
                            digit: $otpDigits[index],
                            isFocused: focusedIndex == index
                        )
                        .focused($focusedIndex, equals: index)
                        .onChange(of: otpDigits[index]) { _, newVal in
                            let filtered = newVal.filter(\.isNumber)
                            // Handle paste of full code
                            if filtered.count == 6 {
                                for i in 0..<6 {
                                    otpDigits[i] = String(filtered[filtered.index(filtered.startIndex, offsetBy: i)])
                                }
                                focusedIndex = nil
                                return
                            }
                            otpDigits[index] = String(filtered.prefix(1))
                            if !filtered.isEmpty && index < 5 {
                                focusedIndex = index + 1
                            } else if filtered.isEmpty && index > 0 {
                                focusedIndex = index - 1
                            }
                        }
                    }
                }

                // Error
                if let error = authViewModel.errorMessage {
                    AuthErrorBanner(message: error)
                }

                // Verify button
                PrimaryButton(
                    title: "Verify",
                    icon: "checkmark",
                    isLoading: authViewModel.isLoading,
                    isDisabled: fullCode.count < 6
                ) {
                    Task { await authViewModel.verifyPhoneOTP(code: fullCode) }
                }

                // Resend
                Button {
                    Task {
                        otpDigits = Array(repeating: "", count: 6)
                        await authViewModel.sendPhoneOTP(phoneNumber: phoneNumber)
                        resendCooldown = 60
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 13))
                        Text(resendCooldown > 0 ? "Resend code in \(resendCooldown)s" : "Resend code")
                            .font(AppFont.subheadline())
                    }
                    .foregroundStyle(resendCooldown > 0 ? Color.textDisabled : Color.brandPrimary)
                }
                .disabled(resendCooldown > 0 || authViewModel.isLoading)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Verify Phone")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focusedIndex = 0 }
        .onReceive(timer) { _ in if resendCooldown > 0 { resendCooldown -= 1 } }
        .onDisappear { authViewModel.errorMessage = nil }
    }
}

private struct OTPDigitBox: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 48, height: 56)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isFocused ? Color.brandPrimary : Color.appBorder, lineWidth: isFocused ? 2 : 1)
            )
    }
}
