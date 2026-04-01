

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var navigateToLogin = false
    @State private var navigateToRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
  
                LinearGradient(
                    colors: [Color.gradientStart, Color.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                 
                    VStack(spacing: AppSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 148, height: 148)
                            Circle()
                                .fill(.white.opacity(0.12))
                                .frame(width: 112, height: 112)
                            Image(systemName: "pills.fill")
                                .font(.system(size: 62, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: AppSpacing.sm) {
                            Text("PillPath")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Your personal medication companion")
                                .font(AppFont.body())
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()

                   
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        WelcomeFeatureRow(
                            icon: "bell.badge.fill",
                            title: "Smart Reminders",
                            subtitle: "Never miss a dose again"
                        )
                        WelcomeFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Adherence Tracking",
                            subtitle: "See your progress over time"
                        )
                        WelcomeFeatureRow(
                            icon: "camera.viewfinder",
                            title: "Prescription Scanner",
                            subtitle: "Scan and import medications instantly"
                        )
                    }
                    .padding(.horizontal, AppSpacing.xl)

                    Spacer()


                    VStack(spacing: AppSpacing.md) {
                        Button {
                            navigateToRegister = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Text("Get Started")
                                    .font(AppFont.headline())
                                    .foregroundStyle(Color.brandPrimary)
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Color.brandPrimary)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white)
                            .clipShape(Capsule())
                        }

                        Button {
                            navigateToLogin = true
                        } label: {
                            Text("Already have an account? ")
                                .foregroundStyle(.white.opacity(0.8))
                            + Text("Sign In")
                                .foregroundStyle(.white)
                                .underline()
                        }
                        .font(AppFont.subheadline())
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
        }
    }
}


private struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(AppFont.subheadline())
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
