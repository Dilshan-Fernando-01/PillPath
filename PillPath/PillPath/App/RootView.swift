//
//  RootView.swift
//  PillPath
//
//  Phase 3 – Part 1: Authentication is bypassed.
//  App launches directly into the Home Dashboard.
//  Re-enable the auth gate in a later phase by switching the flag below.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var settings: SettingsViewModel

    /// Flip to `true` when the Auth flow is ready to be wired up.
    private let authEnabled = false

    var body: some View {
        if authEnabled {
            AuthGateView()
        } else {
            MainTabContainer()
        }
    }
}

// MARK: - Auth Gate (placeholder, used when authEnabled = true)

private struct AuthGateView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabContainer()
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    RootView()
        .environmentObject(SettingsViewModel())
}
