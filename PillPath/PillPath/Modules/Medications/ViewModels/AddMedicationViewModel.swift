//
//  AddMedicationViewModel.swift
//  PillPath — Medications Module
//
//  State container for the 8-step Add Medication wizard.
//  Injected services for full testability.
//

import Foundation
import Combine

@MainActor
final class AddMedicationViewModel: ObservableObject, Identifiable {
    let id = UUID()

    // MARK: - Navigation

    @Published var currentStep: Int = 1
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var didSave: Bool = false
    @Published var savedMedication: Medication?
    var isEditing: Bool = false
    private var editingMedicationId: UUID?

    let totalSteps = 8

    // MARK: - Step 1: Name + FDA Search

    @Published var medicationName: String = ""
    @Published var fdaSearchResults: [MedicationSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedFDAResult: MedicationSearchResult?
    private var searchTask: Task<Void, Never>?

    // MARK: - Step 2: Medication Form

    @Published var selectedForm: MedicationForm = .tablet

    // MARK: - Step 3: Dosage

    @Published var dosageAmount: Double = 1.0
    @Published var dosageUnit: DosageUnit = .pills

    // MARK: - Step 4: Schedule Frequency

    @Published var frequency: ScheduleFrequency = .daily
    // Every X hours
    @Published var intervalHours: Int = 6
    @Published var intervalMinutes: Int = 0
    // Specific days (0=Sun…6=Sat)
    @Published var specificDays: Set<Int> = []
    // Custom dates
    @Published var customDates: [Date] = []

    // MARK: - Step 5: Time of Day + Custom Times

    @Published var selectedTimeLabels: Set<DoseTimeLabel> = []
    @Published var customTimes: [ScheduleTime] = []
    @Published var showCustomTimePicker: Bool = false
    @Published var customTimePickerHour: Int = 9
    @Published var customTimePickerMinute: Int = 0

    // MARK: - Step 6: Meal Timing

    @Published var mealTiming: MealTiming = .none

    // MARK: - Step 7: Advanced Options

    @Published var startDate: Date = .now
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @Published var isOngoing: Bool = true
    @Published var doseReminders: Bool = true
    @Published var notificationOffset: NotificationOffset = .atTime
    @Published var selectedEventId: UUID? = nil
    @Published var availableEvents: [MedicalEvent] = []
    @Published var displayName: String = ""
    @Published var notes: String = ""
    @Published var currentQuantity: String = ""
    @Published var lowQuantityAlert: Bool = false
    @Published var lowQuantityThreshold: String = "5"
    // Photo
    @Published var photoURL: String? = nil

    // MARK: - Services

    private let medicationService: MedicationServiceProtocol
    private let scheduleService: ScheduleServiceProtocol
    private let doseTrackingService: DoseTrackingServiceProtocol
    private let fdaService: FDAServiceProtocol
    private let eventService: EventServiceProtocol

    init(
        medicationService: MedicationServiceProtocol? = nil,
        scheduleService: ScheduleServiceProtocol? = nil,
        doseTrackingService: DoseTrackingServiceProtocol? = nil,
        fdaService: FDAServiceProtocol? = nil,
        eventService: EventServiceProtocol? = nil
    ) {
        self.medicationService  = medicationService  ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
        self.scheduleService    = scheduleService    ?? DIContainer.shared.resolve(ScheduleServiceProtocol.self)
        self.doseTrackingService = doseTrackingService ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
        self.fdaService         = fdaService         ?? DIContainer.shared.resolve(FDAServiceProtocol.self)
        self.eventService       = eventService       ?? DIContainer.shared.resolve(EventServiceProtocol.self)
    }

    /// Convenience factory for edit mode — pre-fills all state from an existing medication + schedule.
    static func editing(medication: Medication, schedule: MedicationSchedule? = nil) -> AddMedicationViewModel {
        let vm = AddMedicationViewModel()
        vm.isEditing          = true
        vm.editingMedicationId = medication.id
        vm.currentStep        = 8   // Jump straight to review

        // Step 1
        vm.medicationName = medication.name
        // Step 2
        vm.selectedForm   = medication.form
        // Step 3
        vm.dosageAmount   = medication.dosageAmount
        vm.dosageUnit     = medication.dosageUnit
        // Step 7
        vm.displayName    = medication.displayName ?? ""
        vm.notes          = medication.notes ?? ""
        vm.currentQuantity = medication.currentQuantity > 0 ? String(medication.currentQuantity) : ""
        vm.lowQuantityAlert     = medication.lowQuantityAlert
        vm.lowQuantityThreshold = String(medication.lowQuantityThreshold)

        if let s = schedule {
            vm.frequency     = s.frequency
            vm.intervalHours = s.intervalHours
            vm.specificDays  = Set(s.specificDays)
            vm.mealTiming    = s.mealTiming
            vm.startDate     = s.startDate
            vm.isOngoing     = s.isOngoing
            vm.doseReminders = s.doseReminders
            vm.notificationOffset = s.notificationOffsetMinutes
            if let end = s.endDate { vm.endDate = end }

            // Rebuild time labels + custom times
            for t in s.scheduleTimes {
                if t.label == .custom { vm.customTimes.append(t) }
                else { vm.selectedTimeLabels.insert(t.label) }
            }
        }
        return vm
    }

    /// Pre-fill name + optional dosage hint (used from OCR import flow)
    static func prefilled(name: String, form: MedicationForm = .tablet, dosage: Double = 1.0, unit: DosageUnit = .pills) -> AddMedicationViewModel {
        let vm = AddMedicationViewModel()
        vm.medicationName = name
        vm.selectedForm   = form
        vm.dosageAmount   = dosage
        vm.dosageUnit     = unit
        vm.currentStep    = 1
        return vm
    }

    // MARK: - Navigation

    var canProceed: Bool {
        switch currentStep {
        case 1: return !medicationName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return true  // form always has a selection
        case 3: return dosageAmount > 0
        case 4: return isStep4Valid
        case 5: return !selectedTimeLabels.isEmpty || !customTimes.isEmpty
        case 6: return true
        case 7: return true
        case 8: return true
        default: return false
        }
    }

    func nextStep() {
        guard canProceed, currentStep < totalSteps else { return }
        if currentStep == 7 { loadEvents() }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }

    func goToStep(_ step: Int) {
        guard step >= 1, step <= totalSteps else { return }
        currentStep = step
    }

    // MARK: - Step 4 Validation

    private var isStep4Valid: Bool {
        switch frequency {
        case .daily:         return true
        case .everyXHours:   return totalIntervalMinutes >= 30
        case .specificDays:  return !specificDays.isEmpty
        case .alternateDays: return true
        case .custom:        return !customDates.isEmpty
        }
    }

    private var totalIntervalMinutes: Int {
        intervalHours * 60 + intervalMinutes
    }

    // MARK: - Step 1: FDA Search

    func searchFDA(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            fdaSearchResults = []
            return
        }
        searchTask = Task {
            isSearching = true
            do {
                try await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
                guard !Task.isCancelled else { return }
                let results = try await fdaService.search(query: query, limit: 8)
                fdaSearchResults = results
            } catch {
                if !Task.isCancelled { fdaSearchResults = [] }
            }
            isSearching = false
        }
    }

    func applyFDAResult(_ result: MedicationSearchResult) {
        selectedFDAResult = result
        medicationName = result.brandName
        if let form = result.dosageForms.first.flatMap({ MedicationForm(rawValue: $0.lowercased()) }) {
            selectedForm = form
        }
        fdaSearchResults = []
    }

    // MARK: - Step 5: Time Helpers

    func toggleTimeLabel(_ label: DoseTimeLabel) {
        if selectedTimeLabels.contains(label) {
            selectedTimeLabels.remove(label)
        } else {
            selectedTimeLabels.insert(label)
        }
    }

    func addCustomTime() {
        let time = ScheduleTime(hour: customTimePickerHour, minute: customTimePickerMinute, label: .custom)
        customTimes.append(time)
        showCustomTimePicker = false
    }

    func removeCustomTime(_ time: ScheduleTime) {
        customTimes.removeAll { $0.id == time.id }
    }

    // MARK: - Step 7: Load Events

    func loadEvents() {
        Task {
            do {
                availableEvents = try eventService.fetchAll()
            } catch {
                availableEvents = []
            }
        }
    }

    // MARK: - Computed Schedule Times

    /// Builds the final [ScheduleTime] array from selected labels + custom times.
    private var resolvedScheduleTimes: [ScheduleTime] {
        var times: [ScheduleTime] = []
        if selectedTimeLabels.contains(.morning) { times.append(.morning) }
        if selectedTimeLabels.contains(.noon)    { times.append(.noon) }
        if selectedTimeLabels.contains(.evening) { times.append(.evening) }
        if selectedTimeLabels.contains(.night)   { times.append(.night) }
        times.append(contentsOf: customTimes)
        return times
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        saveError = nil

        do {
            // 1. Build Medication domain model
            let medication = Medication(
                id: editingMedicationId ?? UUID(),
                name: medicationName.trimmingCharacters(in: .whitespaces),
                genericName: selectedFDAResult?.genericName,
                displayName: displayName.isEmpty ? nil : displayName.trimmingCharacters(in: .whitespaces),
                form: selectedForm,
                dosageAmount: dosageAmount,
                dosageUnit: dosageUnit,
                instructions: selectedFDAResult?.indications,
                notes: notes.isEmpty ? nil : notes,
                photoURL: photoURL,
                currentQuantity: Int(currentQuantity) ?? 0,
                lowQuantityAlert: lowQuantityAlert,
                lowQuantityThreshold: Int(lowQuantityThreshold) ?? 5,
                sideEffects: selectedFDAResult?.sideEffects ?? [],
                interactions: selectedFDAResult?.interactions.map { [$0] } ?? []
            )

            // 2. Persist medication
            try medicationService.save(medication)

            // 3. Build schedule
            let schedule = MedicationSchedule(
                medicationId: medication.id,
                frequency: frequency,
                intervalHours: totalIntervalMinutes / 60,
                specificDays: Array(specificDays).sorted(),
                scheduleTimes: resolvedScheduleTimes,
                mealTiming: mealTiming,
                startDate: startDate,
                endDate: isOngoing ? nil : endDate,
                isOngoing: isOngoing,
                doseReminders: doseReminders,
                notificationOffsetMinutes: notificationOffset
            )

            // 4. Persist schedule
            try scheduleService.save(schedule, for: medication)

            // 5. Pre-generate upcoming dose logs (7 days)
            try await doseTrackingService.generateUpcomingLogs(for: schedule, days: 7)

            savedMedication = medication
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Review Summaries (used in Step 8)

    var reviewItems: [ReviewItem] {
        var items: [ReviewItem] = [
            ReviewItem(label: "Medication", value: medicationName),
            ReviewItem(label: "Form", value: selectedForm.displayName),
            ReviewItem(label: "Dosage", value: dosageDisplay),
            ReviewItem(label: "Schedule", value: frequency.displayName),
            ReviewItem(label: "Time(s)", value: timeSummary),
            ReviewItem(label: "Meal Timing", value: mealTiming.shortName),
            ReviewItem(label: "Start Date", value: startDate.formatted(.dateTime.day().month().year())),
        ]
        if !isOngoing {
            items.append(ReviewItem(label: "End Date", value: endDate.formatted(.dateTime.day().month().year())))
        }
        if !displayName.isEmpty {
            items.append(ReviewItem(label: "Display Name", value: displayName))
        }
        if let qty = Int(currentQuantity), qty > 0 {
            items.append(ReviewItem(label: "Quantity", value: "\(qty) \(dosageUnit.displayName)"))
        }
        return items
    }

    var dosageDisplay: String {
        let amt = dosageAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(dosageAmount))
            : String(dosageAmount)
        return "\(amt) \(dosageUnit.displayName)"
    }

    var timeSummary: String {
        let labels = selectedTimeLabels.sorted { $0.rawValue < $1.rawValue }.map(\.displayName)
        let custom = customTimes.map(\.displayString)
        let all = labels + custom
        return all.isEmpty ? "—" : all.joined(separator: ", ")
    }

    var frequencySummary: String {
        switch frequency {
        case .daily:         return "Every day"
        case .everyXHours:   return "Every \(intervalHours)h \(intervalMinutes > 0 ? "\(intervalMinutes)m" : "")"
        case .specificDays:  return "\(specificDays.count) days/week"
        case .alternateDays: return "Alternate days"
        case .custom:        return "\(customDates.count) custom dates"
        }
    }
}

// MARK: - ReviewItem

struct ReviewItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}
