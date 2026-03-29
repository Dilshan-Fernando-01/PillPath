//
//  ContentView.swift
//  PillPath
//
//  The original Xcode template ContentView has been replaced by RootView.
//  This file is kept as a thin redirect so any leftover storyboard / preview
//  references do not cause a missing-type error.
//

import SwiftUI

/// Redirects to the real root of the app.
/// All navigation logic lives in App/RootView.swift.
struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsViewModel())
}
