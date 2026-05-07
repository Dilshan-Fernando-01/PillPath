//
//  PillPathApp.swift
//  PillPath
//
//  Entry point. Bootstraps DI, CoreData, and injects global environment objects.
//

import SwiftUI
import UserNotifications


final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct PillPathApp: App {

    @StateObject private var settings = SettingsViewModel()
    private let notificationDelegate = NotificationDelegate()

    init() {
        AppDependencies.register()
        DataSeeder.seedIfNeeded()

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        Task {
            try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .preferredColorScheme(settings.colorScheme.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in }
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("pillpath_language_did_change")
}
