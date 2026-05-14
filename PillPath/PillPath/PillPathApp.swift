
import SwiftUI
import UserNotifications
import FirebaseCore
import GoogleSignIn


final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])

        let userInfo = notification.request.content.userInfo
        let identifier = notification.request.identifier
        let title = notification.request.content.title
        let body = notification.request.content.body
        let inAppService = DIContainer.shared.resolve(InAppNotificationServiceProtocol.self)

        if let typeStr = userInfo["type"] as? String, typeStr == "eventReminder",
           let eventId = userInfo["eventId"] as? String {
            let deepLink = "event_\(eventId)"
            try? inAppService.create(type: .eventReminder, title: title, body: body, deepLink: deepLink)
        } else if identifier.contains("low_qty_") {
            let deepLink = identifier
            try? inAppService.create(type: .lowStock, title: title, body: body, deepLink: deepLink)
        } else if !identifier.isEmpty {
            let deepLink = "push_\(identifier)"
            try? inAppService.create(type: .doseReminder, title: title, body: body, deepLink: deepLink)
        }
    }
}

@main
struct PillPathApp: App {

    @StateObject private var settings = SettingsViewModel()
    private let notificationDelegate = NotificationDelegate()

    init() {
        FirebaseApp.configure()
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
                .environment(\.legibilityWeight, settings.highContrastMode ? .bold : nil)
                .tint(settings.highContrastMode ? Color(hex: "#1A3FB8") : Color.brandPrimary)
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

extension Notification.Name {
    static let languageDidChange      = Notification.Name("pillpath_language_did_change")
    static let dataRestored           = Notification.Name("pillpath_data_restored")
    static let inAppNotificationAdded = Notification.Name("pillpath_inapp_notification_added")
}
