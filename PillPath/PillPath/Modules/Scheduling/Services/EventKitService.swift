
import Combine
import EventKit
import Foundation

final class EventKitService: ObservableObject {

    static let shared = EventKitService()

    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }


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


    @discardableResult
    func syncMedicationToCalendar(
        medicationName: String,
        dosageDisplay: String,
        doseTimes: [Date],
        startDate: Date = .now,
        endDate: Date? = nil,
        notes: String? = nil,
        recurring: Bool = true
    ) -> Int {
        guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else { return 0 }

        let targetCalendar = existingPillPathCalendar() ?? store.defaultCalendarForNewEvents
        let recurrenceEnd: EKRecurrenceEnd? = endDate.map { EKRecurrenceEnd(end: $0) }

        var created = 0
        for time in doseTimes {
            let event = EKEvent(eventStore: store)
            event.title    = "💊 \(medicationName)"
            event.notes    = [dosageDisplay, notes].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
            event.calendar = targetCalendar
            event.startDate = recurring ? alignToToday(time: time, from: startDate) : time
            event.endDate   = event.startDate.addingTimeInterval(15 * 60)

            let alarm = EKAlarm(relativeOffset: -10 * 60)
            event.addAlarm(alarm)

            if recurring {
                let rule = EKRecurrenceRule(
                    recurrenceWith: .daily,
                    interval: 1,
                    end: recurrenceEnd
                )
                event.addRecurrenceRule(rule)
            }

            if (try? store.save(event, span: .futureEvents)) != nil {
                created += 1
            }
        }
        return created
    }

    func removeAllPillPathEvents() -> Int {
        guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else { return 0 }

        let targetCalendar = existingPillPathCalendar()
        let predicate = store.predicateForEvents(
            withStart: Date().addingTimeInterval(-365 * 24 * 3600),
            end: Date().addingTimeInterval(2 * 365 * 24 * 3600),
            calendars: targetCalendar.map { [$0] } ?? nil
        )
        let events = store.events(matching: predicate).filter {
            $0.title?.hasPrefix("💊") == true || $0.calendar?.title == "PillPath Medications"
        }
        var removed = 0
        for event in events {
            if (try? store.remove(event, span: .futureEvents, commit: false)) != nil {
                removed += 1
            }
        }
        try? store.commit()
        return removed
    }


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


    private func existingPillPathCalendar() -> EKCalendar? {
        store.calendars(for: .event).first { $0.title == "PillPath Medications" }
    }

    func syncMedicalEvent(_ event: MedicalEvent) {
        guard authorizationStatus == .fullAccess || authorizationStatus == .writeOnly else { return }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = event.title
        var noteParts: [String] = []
        if let provider = event.provider, !provider.isEmpty { noteParts.append(provider) }
        if let notes = event.notes, !notes.isEmpty { noteParts.append(notes) }
        ekEvent.notes = noteParts.isEmpty ? nil : noteParts.joined(separator: "\n")
        ekEvent.startDate = event.date
        ekEvent.endDate   = event.date.addingTimeInterval(3600)
        ekEvent.calendar  = existingPillPathCalendar() ?? store.defaultCalendarForNewEvents

        let alarm = EKAlarm(relativeOffset: -60 * 60)
        ekEvent.addAlarm(alarm)

        try? store.save(ekEvent, span: .thisEvent, commit: true)
    }

    func requestAccessAndSync(medicalEvent: MedicalEvent) {
        if authorizationStatus == .fullAccess || authorizationStatus == .writeOnly {
            syncMedicalEvent(medicalEvent)
        } else if authorizationStatus == .notDetermined {
            requestAccess { [weak self] granted in
                if granted { self?.syncMedicalEvent(medicalEvent) }
            }
        }
    }

    func createPillPathCalendarIfNeeded() {
        guard existingPillPathCalendar() == nil else { return }
        guard let source = store.defaultCalendarForNewEvents?.source else { return }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title  = "PillPath Medications"
        cal.source = source
        cal.cgColor = CGColor(red: 0.27, green: 0.51, blue: 0.94, alpha: 1) 
        try? store.saveCalendar(cal, commit: true)
    }


    private func alignToToday(time: Date, from base: Date) -> Date {
        let cal = Calendar.current
        let h   = cal.component(.hour,   from: time)
        let m   = cal.component(.minute, from: time)
        return cal.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
    }
}
