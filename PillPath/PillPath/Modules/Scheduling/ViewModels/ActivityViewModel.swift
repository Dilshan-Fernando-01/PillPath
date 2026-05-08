
import Foundation
import Combine

@MainActor
final class ActivityViewModel: ObservableObject {

   

    @Published var weekOffset: Int = 0          
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var dayStatuses: [Date: DayStatus] = [:]
    @Published var selectedDayDoses: [DoseDisplayItem] = []
    @Published var scheduleFilter: ScheduleFilter = .today

   

    @Published var activeMedications: [Medication] = []
    @Published var stoppedMedications: [Medication] = []
    @Published var medicationSearch: String = ""

    var filteredActiveMedications: [Medication] {
        guard !medicationSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return activeMedications }
        return activeMedications.filter { $0.name.localizedCaseInsensitiveContains(medicationSearch) }
    }

    var filteredStoppedMedications: [Medication] {
        guard !medicationSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return stoppedMedications }
        return stoppedMedications.filter { $0.name.localizedCaseInsensitiveContains(medicationSearch) }
    }

  

    @Published var allEvents: [MedicalEvent] = []
    @Published var eventsByMonth: [(month: Date, events: [MedicalEvent])] = []
    @Published var eventSearch: String = ""

    var filteredEventsByMonth: [(month: Date, events: [MedicalEvent])] {
        guard !eventSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return eventsByMonth }
        return eventsByMonth.compactMap { group in
            let filtered = group.events.filter {
                $0.title.localizedCaseInsensitiveContains(eventSearch) ||
                ($0.provider?.localizedCaseInsensitiveContains(eventSearch) ?? false)
            }
            return filtered.isEmpty ? nil : (month: group.month, events: filtered)
        }
    }

  

    @Published var scheduleSearch: String = ""

    var filteredSelectedDayDoses: [DoseDisplayItem] {
        guard !scheduleSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return selectedDayDoses }
        return selectedDayDoses.filter { $0.medicationName.localizedCaseInsensitiveContains(scheduleSearch) }
    }

   

    @Published var isLoading = false
    @Published var errorMessage: String?

   

    @Published var historyItems: [DoseHistoryItem] = []

   

    enum DayStatus { case allTaken, hasMissed, hasPending, noData }

    struct DoseHistoryItem: Identifiable {
        let id: UUID
        let medicationName: String
        let dosageDisplay: String
        let scheduledAt: Date
        let takenAt: Date?
        let status: DoseStatus
        let scheduledLabel: DoseTimeLabel
        let takenLabel: DoseTimeLabel?

      var isOutOfWindow: Bool {
            guard status == .taken, let tl = takenLabel else { return false }
            return tl != scheduledLabel
        }
    }

    enum ScheduleFilter: CaseIterable {
        case today, thisWeek, thisMonth
        var displayName: String {
            switch self {
            case .today:     return "Today"
            case .thisWeek:  return "This Week"
            case .thisMonth: return "This Month"
            }
        }
    }

   

    private let scheduleService: ScheduleServiceProtocol
    private let doseTrackingService: DoseTrackingServiceProtocol
    private let medicationService: MedicationServiceProtocol
    private let eventService: EventServiceProtocol

   

    init(
        scheduleService: ScheduleServiceProtocol? = nil,
        doseTrackingService: DoseTrackingServiceProtocol? = nil,
        medicationService: MedicationServiceProtocol? = nil,
        eventService: EventServiceProtocol? = nil
    ) {
        self.scheduleService     = scheduleService     ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
        self.doseTrackingService = doseTrackingService ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
        self.medicationService   = medicationService   ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
        self.eventService        = eventService        ?? DIContainer.shared.resolve(EventServiceProtocol.self)
    }

 

    func loadAll() {
        loadScheduleData()
        loadMedications()
        loadEvents()
    }

  var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday + weekOffset * 7, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        loadDosesForSelectedDate()
    }

    func changeWeek(by delta: Int) {
        weekOffset += delta
    }

    func loadScheduleData() {
        loadWeekStatuses()
        loadDosesForSelectedDate()
    }

    private func loadWeekStatuses() {
        let days = weekDays
        var statuses: [Date: DayStatus] = [:]
        do {
            for day in days {
                let logs = try doseTrackingService.fetchLogs(on: day)
                if logs.isEmpty {
                    statuses[day] = .noData
                } else if logs.allSatisfy({ $0.status == .taken }) {
                    statuses[day] = .allTaken
                } else if logs.contains(where: { $0.status == .missed }) {
                    statuses[day] = .hasMissed
                } else {
                    statuses[day] = .hasPending
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        dayStatuses = statuses
    }

    func loadDosesForSelectedDate() {
        do {
            try doseTrackingService.detectAndMarkMissed()
            let schedules  = try scheduleService.fetchAll().filter(\.isActive)
            let medications = try medicationService.fetchAll()
            let medMap = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })
            let logs   = try doseTrackingService.fetchLogs(on: selectedDate)
            let logMap = Dictionary(grouping: logs, by: { $0.scheduleId })
            let calendar = Calendar.current
            var items: [DoseDisplayItem] = []

            for schedule in schedules {
                guard let med = medMap[schedule.medicationId],
                      med.isActive else { continue }
                let daysAhead = max(2, (calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: selectedDate).day ?? 0) + 2)
                let doseTimes = ScheduleCalculator.upcomingDoseTimes(for: schedule, days: daysAhead)
                    .filter { calendar.isDate($0, inSameDayAs: selectedDate) }

                for doseTime in doseTimes {
                    let hour      = calendar.component(.hour, from: doseTime)
                    let timeLabel = DoseTimeLabel.from(hour: hour)
                    let matchedLog = logMap[schedule.id]?.first {
                        abs($0.scheduledAt.timeIntervalSince(doseTime)) < 60
                    }
                    let status: DoseStatus
                    if let log = matchedLog {
                        status = log.status
                    } else if Date.now > doseTime.addingTimeInterval(3600) && calendar.isDateInToday(selectedDate) {
                        status = .missed
                    } else {
                        status = .pending
                    }
                    items.append(DoseDisplayItem(
                        id: matchedLog?.id ?? UUID(),
                        medicationId: med.id,
                        scheduleId: schedule.id,
                        medicationName: med.name,
                        dosageDisplay: med.dosageDisplay,
                        medicationCategory: med.instructions,
                        usageNote: med.notes,
                        scheduledAt: doseTime,
                        timeLabel: timeLabel,
                        mealTiming: schedule.mealTiming,
                        status: status,
                        logId: matchedLog?.id
                    ))
                }
            }
            selectedDayDoses = items.sorted { $0.scheduledAt < $1.scheduledAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }



    func loadMedications() {
        do {
            let all = try medicationService.fetchAll()
            activeMedications  = all.filter(\.isActive)
            stoppedMedications = all.filter { !$0.isActive }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleActive(_ medication: Medication, change: MedicationStatusChange) {
        var updated = medication
        updated.isActive = change.isActive
        updated.statusChange = change
        do {
            try medicationService.save(updated)
            loadMedications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMedication(_ medication: Medication) {
        do {
            try medicationService.delete(medication)
            loadMedications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

   

    func loadEvents() {
        do {
            let events = try eventService.fetchAll()
            allEvents = events
            eventsByMonth = groupByMonth(events)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveEvent(_ event: MedicalEvent) {
        do {
            try eventService.save(event)
            loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEvent(_ event: MedicalEvent) {
        do {
            try eventService.delete(event)
            loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

  

    func loadHistory(from start: Date, to end: Date) {
        do {
            let logs = try doseTrackingService.fetchLogs(from: start, to: end)
            let allMeds = activeMedications + stoppedMedications
            let medMap = Dictionary(uniqueKeysWithValues: allMeds.map { ($0.id, $0) })
            let calendar = Calendar.current

            historyItems = logs.compactMap { log -> DoseHistoryItem? in
                guard log.status != .pending else { return nil }
                guard let med = medMap[log.medicationId] else { return nil }
                let scheduledHour = calendar.component(.hour, from: log.scheduledAt)
                let scheduledLabel = DoseTimeLabel.from(hour: scheduledHour)
                var takenLabel: DoseTimeLabel? = nil
                if let takenAt = log.takenAt {
                    let takenHour = calendar.component(.hour, from: takenAt)
                    takenLabel = DoseTimeLabel.from(hour: takenHour)
                }
                return DoseHistoryItem(
                    id: log.id,
                    medicationName: med.name,
                    dosageDisplay: med.dosageDisplay,
                    scheduledAt: log.scheduledAt,
                    takenAt: log.takenAt,
                    status: log.status,
                    scheduledLabel: scheduledLabel,
                    takenLabel: takenLabel
                )
            }.sorted { $0.scheduledAt > $1.scheduledAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

  

    private func groupByMonth(_ events: [MedicalEvent]) -> [(month: Date, events: [MedicalEvent])] {
        let calendar = Calendar.current
        var groups: [(month: Date, events: [MedicalEvent])] = []
        var seen: [Date: Int] = [:]  
        for event in events {
            let comps  = calendar.dateComponents([.year, .month], from: event.date)
            let month  = calendar.date(from: comps)!
            if let idx = seen[month] {
                groups[idx].events.append(event)
            } else {
                seen[month] = groups.count
                groups.append((month: month, events: [event]))
            }
        }
        return groups.sorted { $0.month > $1.month }
    }
}
