

import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleNotifications(for schedule: MedicationSchedule, medication: Medication)
    func cancelNotifications(for scheduleId: UUID)
    func cancelAll()
}

final class NotificationService: NotificationServiceProtocol {

    private let center = UNUserNotificationCenter.current()

   

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

  

    func scheduleNotifications(for schedule: MedicationSchedule, medication: Medication) {
       
        let doseTimes = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: 7)

        for doseTime in doseTimes {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(medication.name)"
            content.body  = "\(medication.dosageDisplay) — \(schedule.mealTiming.shortName)"
            content.sound = .default
            content.categoryIdentifier = AppConstants.Notifications.medicationReminderCategory

            let fireDate = doseTime.addingTimeInterval(
                -TimeInterval(schedule.notificationOffsetMinutes.rawValue * 60)
            )
            guard fireDate > .now else { continue }

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(schedule.id.uuidString)_\(Int(doseTime.timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error { print("Notification schedule error: \(error)") }
            }
        }
    }



    func cancelNotifications(for scheduleId: UUID) {
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(scheduleId.uuidString) }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
