//
//  LoginView.swift
//  PillPath — Authentication Module
//
//  Placeholder — UI will be implemented from Figma design.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("PillPath")
                .font(.largeTitle.bold())

            // TODO: Replace with Figma design
            Text("Login — coming soon")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview { LoginView() }
