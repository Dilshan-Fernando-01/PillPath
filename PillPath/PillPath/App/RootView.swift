

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var settings: SettingsViewModel

    var body: some View {
        AuthGateView()
    }
}



private struct AuthGateView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabContainer()
                    .transition(.opacity)
            } else if authViewModel.isLocked {
                NavigationStack {
                    LoginView()
                        .navigationBarBackButtonHidden(true)
                }
                .transition(.opacity)
            } else {
                WelcomeView()
                    .transition(.opacity)
            }
        }
        .environmentObject(authViewModel)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isLocked)
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsViewModel())
}
