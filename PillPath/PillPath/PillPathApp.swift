//
//  PillPathApp.swift
//  PillPath
//
//  Entry point. Bootstraps DI, CoreData, and injects global environment objects.
//

import SwiftUI

@main
struct PillPathApp: App {

    // Global settings — injected as EnvironmentObject so every view can read them
    @StateObject private var settings = SettingsViewModel()

    init() {
        AppDependencies.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .preferredColorScheme(settings.colorScheme.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                    // SwiftUI environment will re-render automatically via SettingsViewModel
                }
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("pillpath_language_did_change")
}
