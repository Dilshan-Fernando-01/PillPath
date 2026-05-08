

import Foundation
@testable import PillPath

final class MockNotificationService: NotificationServiceProtocol {
    var requestPermissionResult = false
    var scheduledNotificationsCount = 0
    var lowQuantityAlertCount = 0
    var cancelledScheduleIds: [UUID] = []
    var cancelAllCalled = false

    func requestPermission() async -> Bool { requestPermissionResult }

    func scheduleNotifications(for schedule: MedicationSchedule, medication: Medication) {
        scheduledNotificationsCount += 1
    }

    func scheduleLowQuantityAlert(for medication: Medication) {
        lowQuantityAlertCount += 1
    }

    func cancelNotifications(for scheduleId: UUID) {
        cancelledScheduleIds.append(scheduleId)
    }

    func cancelAll() {
        cancelAllCalled = true
    }
}
