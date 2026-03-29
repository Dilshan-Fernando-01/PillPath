//
//  EventKitService.swift
//  PillPath — Scheduling Module
//
//  Integrates with Apple EventKit to sync medication schedules to the
//  user's iOS Calendar as recurring events with dose-time alerts.
//

import Combine
import EventKit
import Foundation

final class EventKitService: ObservableObject {

    static let shared = EventKitService()

    private let store = EKEventStore()

    /// Published so UI can react to permission state
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Request Access

    /// Requests calendar write access. Calls completion on the main thread.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            store.requestWriteOnlyAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted)
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted)
                }
            }
        }
    }

    // MARK: - Sync Medication Schedule

    /// Creates a recurring calendar event for each daily dose of the medication.
    /// Returns the number of events created.
    @discardableResult
    func syncMedicationToCalendar(
        medicationName: String,
        dosageDisplay: String,
        doseTimes: [Date],
        startDate: Date = .now,
        notes: String? = nil
    ) -> Int {
        guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else { return 0 }

        let calendar = EKCalendar.init(for: .event, eventStore: store)

        // Use the app's dedicated calendar if it exists, otherwise use the default
        let targetCalendar = existingPillPathCalendar() ?? store.defaultCalendarForNewEvents

        var created = 0
        for time in doseTimes {
            let event = EKEvent(eventStore: store)
            event.title    = "💊 \(medicationName)"
            event.notes    = [dosageDisplay, notes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
            event.calendar = targetCalendar
            event.startDate = alignToToday(time: time, from: startDate)
            event.endDate   = event.startDate.addingTimeInterval(15 * 60) // 15-min duration

            // Alert 10 minutes before
            let alarm = EKAlarm(relativeOffset: -10 * 60)
            event.addAlarm(alarm)

            // Repeat daily
            let rule = EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            )
            event.addRecurrenceRule(rule)

            if (try? store.save(event, span: .futureEvents)) != nil {
                created += 1
            }
        }
        _ = calendar // silence unused warning
        return created
    }

    // MARK: - Remove Medication Events

    /// Removes all PillPath calendar events that match the medication name.
    func removeMedicationEvents(medicationName: String) {
        guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else { return }

        let title = "💊 \(medicationName)"
        let predicate = store.predicateForEvents(
            withStart: Date().addingTimeInterval(-365 * 24 * 3600),
            end: Date().addingTimeInterval(365 * 24 * 3600),
            calendars: nil
        )
        let events = store.events(matching: predicate).filter { $0.title == title }
        for event in events {
            try? store.remove(event, span: .futureEvents)
        }
    }

    // MARK: - Calendar Management

    /// Returns the existing PillPath calendar if it was previously created.
    private func existingPillPathCalendar() -> EKCalendar? {
        store.calendars(for: .event).first { $0.title == "PillPath Medications" }
    }

    /// Creates a dedicated PillPath calendar in the user's default source.
    func createPillPathCalendarIfNeeded() {
        guard existingPillPathCalendar() == nil else { return }
        guard let source = store.defaultCalendarForNewEvents?.source else { return }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title  = "PillPath Medications"
        cal.source = source
        cal.cgColor = CGColor(red: 0.27, green: 0.51, blue: 0.94, alpha: 1) // brand blue
        try? store.saveCalendar(cal, commit: true)
    }

    // MARK: - Helpers

    private func alignToToday(time: Date, from base: Date) -> Date {
        let cal = Calendar.current
        let h   = cal.component(.hour,   from: time)
        let m   = cal.component(.minute, from: time)
        return cal.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }
}
