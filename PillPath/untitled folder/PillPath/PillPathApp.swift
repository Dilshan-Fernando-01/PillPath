

import SwiftUI

@main
struct PillPathApp: App {

    
    @StateObject private var settings = SettingsViewModel()

    init() {
        AppDependencies.register()
        DataSeeder.seedIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .preferredColorScheme(settings.colorScheme.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                   
                }
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("pillpath_language_did_change")
}
