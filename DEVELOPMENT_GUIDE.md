# PillPath — Development Guide

> **Living document.** Update this as the project evolves. Every session should leave this file more complete than it was.

---

## Project Overview

**PillPath** is an iOS medication management app built with SwiftUI.
Target: Final-year university project → production-quality code standards.

| Item | Detail |
|------|--------|
| Platform | iOS 17+ |
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Architecture | MVVM + Protocol-oriented Services |
| Local Storage | CoreData |
| External APIs | openFDA (`api.fda.gov`) |
| OCR | Apple Vision framework (on-device) |
| Testing | XCTest — unit tests mandatory for all ViewModels & Services |

---

## Folder Structure

```
PillPath/                          ← Xcode project root
├── App/
│   ├── PillPathApp.swift          ← @main entry point, DI bootstrap
│   ├── AppDependencies.swift      ← All service registrations (one place)
│   └── RootView.swift             ← Auth gate + MainTabView
│
├── Core/
│   ├── DI/
│   │   └── DIContainer.swift      ← Lightweight DI container (no 3rd party)
│   ├── Network/
│   │   ├── NetworkClient.swift    ← Generic async/await HTTP client
│   │   ├── APIEndpoint.swift      ← Protocol all endpoints conform to
│   │   ├── NetworkError.swift     ← Typed errors
│   │   └── OpenFDAEndpoint.swift  ← openFDA specific endpoints
│   ├── Storage/
│   │   └── CoreDataStack.swift    ← NSPersistentContainer singleton
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── Color+Extensions.swift
│
├── Modules/
│   ├── Authentication/
│   │   ├── Models/User.swift
│   │   ├── Views/LoginView.swift
│   │   ├── ViewModels/AuthViewModel.swift
│   │   └── Services/AuthService.swift
│   ├── Medications/
│   │   ├── Models/Medication.swift
│   │   ├── Views/MedicationsListView.swift
│   │   ├── ViewModels/MedicationsViewModel.swift
│   │   └── Services/MedicationService.swift  ← CoreData CRUD + openFDA search
│   ├── Scheduling/
│   │   ├── Models/Schedule.swift             ← MedicationSchedule, DoseLog, DoseStatus
│   │   ├── Views/ScheduleView.swift
│   │   ├── ViewModels/ScheduleViewModel.swift
│   │   └── Services/ScheduleService.swift    ← CoreData + local notifications
│   ├── OCR/
│   │   ├── Models/OCRResult.swift
│   │   ├── Views/OCRScanView.swift
│   │   ├── ViewModels/OCRViewModel.swift
│   │   └── Services/OCRService.swift         ← Apple Vision VNRecognizeTextRequest
│   ├── Analytics/
│   │   ├── Models/AdherenceRecord.swift
│   │   ├── Views/AnalyticsDashboardView.swift
│   │   ├── ViewModels/AnalyticsViewModel.swift
│   │   └── Services/AnalyticsService.swift
│   └── Settings/
│       ├── Models/AppSettings.swift          ← AppLanguage, AppTextSize, AppColorScheme
│       ├── Views/SettingsView.swift
│       └── ViewModels/SettingsViewModel.swift ← UserDefaults, injected as @EnvironmentObject
│
├── Shared/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── EmptyStateView.swift
│   ├── Utilities/
│   │   ├── LocalizationManager.swift         ← Runtime language switching, L("key") helper
│   │   └── DateFormatterHelper.swift
│   └── Constants/
│       └── AppConstants.swift
│
├── Resources/
│   ├── en.lproj/Localizable.strings
│   ├── si.lproj/Localizable.strings          ← Sinhala (partial)
│   ├── ta.lproj/Localizable.strings          ← Tamil (partial)
│   └── Assets.xcassets/
│
└── PillPathTests/
    ├── Mocks/
    │   ├── MockMedicationService.swift
    │   ├── MockScheduleService.swift
    │   └── MockNetworkClient.swift
    └── Modules/
        ├── Medications/MedicationsViewModelTests.swift
        ├── Settings/SettingsViewModelTests.swift
        ├── Analytics/AnalyticsViewModelTests.swift
        └── Core/Network/NetworkClientTests.swift
```

---

## Architecture: MVVM + Protocol Services

```
┌──────────────────────────────────────────────────────────┐
│  View  (SwiftUI)                                         │
│  • Renders state from ViewModel                          │
│  • Calls ViewModel methods on user actions               │
│  • No business logic — layout only                       │
└──────────────────┬───────────────────────────────────────┘
                   │ @StateObject / @EnvironmentObject
┌──────────────────▼───────────────────────────────────────┐
│  ViewModel  (@MainActor, ObservableObject)               │
│  • @Published properties drive the View                  │
│  • Coordinates between Services                          │
│  • No UIKit / CoreData imports                           │
└──────────┬───────────────────────┬───────────────────────┘
           │ protocol call         │ protocol call
┌──────────▼──────────┐  ┌────────▼──────────────────────┐
│  Service (Protocol) │  │  NetworkClient (Protocol)     │
│  • CoreData CRUD    │  │  • Async/await HTTP            │
│  • Business logic   │  │  • openFDA API calls           │
└──────────┬──────────┘  └────────────────────────────────┘
           │
┌──────────▼──────────┐
│  CoreDataStack      │
│  • NSPersistentCont.│
│  • viewContext      │
└─────────────────────┘
```

### Data Flow Rule
> **View → ViewModel → Service → Storage/Network**
> Data flows back via `@Published` properties. Views never call Services directly.

---

## Dependency Injection

```swift
// Register once at startup (AppDependencies.swift)
DIContainer.shared.registerSingleton(MedicationServiceProtocol.self) {
    MedicationService(coreData: .shared)
}

// Resolve in ViewModel init
init(service: MedicationServiceProtocol = DIContainer.shared.resolve(MedicationServiceProtocol.self)) {
    self.service = service
}

// Override in tests — no DI container needed
let vm = MedicationsViewModel(service: MockMedicationService())
```

---

## Settings: Text Size, Language, Dark Mode

`SettingsViewModel` is injected at root as `@EnvironmentObject`.

| Feature | Implementation |
|---------|---------------|
| Text Size | `AppTextSize.scaleFactor` applied via `View+Extensions` |
| Dark Mode | `settings.colorScheme.colorScheme` passed to `.preferredColorScheme()` on `WindowGroup` |
| Language | `LocalizationManager.setLanguage(_:)` swaps the active `Bundle`; `L("key")` macro everywhere |

---

## External APIs

### openFDA
- Base URL: `https://api.fda.gov`
- No API key required (rate limited to 240 requests/minute/IP)
- Endpoints used: `/drug/label.json`, `/drug/event.json`
- All endpoint definitions live in `Core/Network/OpenFDAEndpoint.swift`
- Response models live in `Modules/Medications/Services/MedicationService.swift`

### OCR (Apple Vision)
- Fully on-device — `VNRecognizeTextRequest` in `OCRService.swift`
- No internet required for scanning
- After scanning, raw text is passed to openFDA to enrich medication details
- No third-party OCR SDK needed

---

## Local Storage (CoreData)

**Model file:** `PillPath.xcdatamodeld`

Entities to add (TODO — implement in Xcode data model editor):

| Entity | Key Attributes |
|--------|---------------|
| `MedicationEntity` | id (UUID), name, genericName, dosage, form, addedAt |
| `ScheduleEntity` | id (UUID), medicationId, frequency, startDate, endDate, isActive |
| `ScheduleTimeEntity` | id (UUID), hour, minute (relationship → ScheduleEntity) |
| `DoseLogEntity` | id (UUID), scheduleId, scheduledAt, takenAt, status |

All CoreData operations go through `CoreDataStack.shared.viewContext`.
Background work uses `CoreDataStack.shared.newBackgroundContext()`.

---

## Localisation Conventions

- All user-facing strings use `L("key")` — never hardcoded literals in Views.
- Key format: `module_screen_element` (e.g. `med_add`, `settings_text_size`)
- Master string file: `Resources/en.lproj/Localizable.strings`
- Add new keys to **en** first, then si/ta.
- `LocalizationManager.setLanguage(_:)` is called when `SettingsViewModel.language` changes.

---

## Unit Testing Conventions

- All ViewModels and Services **must** have unit tests.
- Use `Mock*` classes from `PillPathTests/Mocks/` — never real CoreData/network in unit tests.
- `@MainActor` on test classes that test `@MainActor` ViewModels.
- Test naming: `test_methodName_condition_expectedResult`
- Use `XCTest` only — no third-party test libraries.

---

## Development Order (Step-by-Step)

### Phase 1 — Architecture (CURRENT ✅)
- [x] Project folder structure
- [x] MVVM scaffolding for all modules
- [x] DI container
- [x] Network layer (openFDA)
- [x] CoreData stack
- [x] Settings (text size, language, dark mode)
- [x] Localization infrastructure (en/si/ta)
- [x] Unit test scaffolding + first tests

### Phase 2 — Data Layer + Services ✅
> Completed 2026-03-28

- [x] CoreData model — 5 entities (MedicationEntity, ScheduleEntity, ScheduleTimeEntity, DoseLogEntity, MedicalEventEntity)
- [x] NSManagedObject subclasses (manual, no codegen)
- [x] Entity ↔ Domain mappers (MedicationMapper, ScheduleMapper, DoseLogMapper, MedicalEventMapper, JSONHelper)
- [x] Updated domain models — Medication (dosageUnit, displayName, inventory), Schedule (full frequency options, mealTiming, notifications)
- [x] MedicationService — real CoreData CRUD + openFDA search
- [x] ScheduleService — real CoreData + notification scheduling
- [x] DoseTrackingService — mark taken/skipped, detect missed, generate upcoming logs
- [x] ScheduleCalculator — pure business logic (daily/interval/specificDays/alternateDays, adherence %, missed detection)
- [x] FDAService — clean DTO layer (MedicationSearchResult), isolates raw openFDA JSON
- [x] EventService — medical events CRUD
- [x] NotificationService — UNUserNotificationCenter wrapper
- [x] AnalyticsService — per-medication adherence + streak calculation
- [x] BiometricAuthService stub (LocalAuthentication)
- [x] GoogleSSOService stub
- [x] AppTheme — full design token system (colors, typography, spacing, radius)
- [x] Design system components: PrimaryButton, SecondaryButton, TextLinkButton, StepProgressView, MedicationTypeCard, TimeOfDayCard, RadioListItem, MealTimingSelector, DosagePicker, SuggestionChip
- [x] Navigation: BottomNavigationBar (HOME|MEDS|FAB|SCAN|ACTIVITY), QuickActionsPanel, MainTabContainer
- [x] SuccessView (generic reusable)
- [x] New tests: ScheduleCalculatorTests, MedicationModelTests, MockDoseTrackingService

### Phase 3 — Full UI (Figma → SwiftUI)

#### Part 1 — Home Dashboard ✅ (2026-03-28)
- [x] HomeViewModel — date selection, grouping by DoseTimeLabel + MealTiming, missed detection, next dose calc, markTaken/markAllTaken
- [x] CalendarStripView — horizontal 5-day strip, scrollable ±30 days, gradient selected cell
- [x] DoseItemRow — pill icon, name/category, status circle/checkmark/warning
- [x] MealTimingSection — BEFORE/WITH/AFTER MEAL card with empty state
- [x] TimeOfDayGroupSection — MORNING/NOON/EVENING/NIGHT with missed warning banner
- [x] NextDoseCard — next upcoming dose highlight with time remaining chip
- [x] FullScheduleSheet — bottom sheet showing all groups for selected date
- [x] HomeView — full screen wiring all components + emergency call button (tel://)
- [x] EmergencyContact model + UserDefaults persistence in SettingsViewModel
- [x] RootView — auth bypassed, launches MainTabContainer directly (flip `authEnabled = true` later)
- [x] MainTabContainer — HomeView wired as `.home` tab

#### Part 2 — Add Medication Flow ✅ (2026-03-28)
- [x] AddMedicationViewModel — 8-step state, FDA search (debounced), save() → Medication + Schedule + DoseLog generation
- [x] AddMedicationFlowView — NavigationStack container, StepProgressView header, sticky footer (Continue / Save), SuccessView on save
- [x] Step 1 — Name + openFDA auto-complete suggestions
- [x] Step 2 — Medication form (tablet/capsule/liquid/injection/patch/inhaler/other)
- [x] Step 3 — Dosage (DosagePicker quick chips + custom amount entry + unit selector)
- [x] Step 4 — Schedule frequency: Daily | Every X hours (hrs+mins pickers) | Specific days (day strip) | Alternate days | Custom dates (calendar)
- [x] Step 5 — Time of day (TimeOfDayGrid multi-select) + custom time wheel picker
- [x] Step 6 — Meal timing (MealTimingSelector + No Preference option)
- [x] Step 7 — Advanced: start/end dates, ongoing toggle, reminders + offset, event link (EventService), photo (PhotosPicker), display name, notes, inventory qty + low-alert
- [x] Step 8 — Full review with per-section Edit buttons (goToStep), save → SuccessView
- [x] MedicationsListView — real list with search, swipe-to-delete, + button opens AddMedicationFlowView sheet
- [x] AddMedStepHelpers — stepHeader(), SectionLabel, FieldCard shared helpers

#### Remaining Part 3+
- [ ] Medications detail screen
- [ ] Schedule / Today's doses screen
- [ ] OCR scan + result screen
- [ ] Analytics dashboard (charts + adherence)
- [ ] Settings screen (text size, language, dark mode)
- [ ] All screens dark mode tested
- [ ] Accessibility (Dynamic Type, VoiceOver labels)

**Components ready (reuse these):**
- Buttons: PrimaryButton, SecondaryButton, TextLinkButton
- StepProgressView, MedicationTypeCard, TimeOfDayCard
- RadioListItem, MealTimingSelector, DosagePicker, SuggestionChip
- BottomNavigationBar, QuickActionsPanel, SuccessView, LoadingView, ErrorView, EmptyStateView

### Phase 4 Part 1 — Prescription Bulk Upload (OCR + FDA Validation) ✅ (2026-03-28)
- [x] Enhanced OCRService — `.accurate` recognition, `customWords` medical hints, image orientation fix, top-2 candidate selection for handwriting
- [x] MedicationExtractionService — heuristic line parser → candidate drug names (stop-word filter, dosage regex, normalisation)
- [x] PrescriptionValidationService — concurrent FDA validation, Jaro-Winkler similarity (0–100), MatchStatus (exact/partial/none), auto-accept ≥75%
- [x] ScannedMedicationItem — model with originalName, fdaMatchName, confidence, action (pending/accepted/rejected), user-editable name, dosage suggestion
- [x] BulkImportService — deduplication by name, creates Medication + MedicationSchedule (daily/morning default) + 7-day dose logs per import
- [x] PrescriptionScanViewModel — pipeline: camera → OCR → extract → validate (concurrent) → review → import; accept/reject/edit/addManual/acceptAll
- [x] ImagePickerView — UIImagePickerController wrapper, supports camera + photo library
- [x] OCRScanView — step router (camera/analyzing/review/done), camera overlay with frame guide, gallery button
- [x] PrescriptionAnalyzingView — animated spinning ring + document icon + animated dots
- [x] PrescriptionReviewView — scanned items list with accept/edit/reject, manual add field, "Save All" button with accepted count
- [x] MedicationReviewCard — accepted indicator, confidence badge (HIGH/REVIEW/NO MATCH), Edit button
- [x] QuickEditSheet — inline name + dosage + schedule type + time of day; "Advance Settings" redirects to full Add Medication stepper
- [x] AppDependencies — registered OCRService, MedicationExtractionService, PrescriptionValidationService, BulkImportService
- [x] Notification.switchToHomeTab — OCR success screen → Home tab switch via NotificationCenter
- [x] Phase 3 Part 2 fixes: dose undo (markPending), MedicationActionsSheet (View Details / Mark Inactive / Delete), edit flow pre-fills AddMedicationViewModel at Step 8

### Phase 4 Part 2+ — Polish & Testing
- [ ] Full unit test coverage for all ViewModels & Services
- [ ] UI tests for critical flows (add medication, mark dose)
- [ ] Performance — large medication lists
- [ ] Offline handling
- [ ] App icon & launch screen

---

## Naming Conventions

| Layer | Convention | Example |
|-------|-----------|---------|
| Views | `{Feature}View` | `MedicationsListView` |
| ViewModels | `{Feature}ViewModel` | `MedicationsViewModel` |
| Services | `{Feature}Service` | `MedicationService` |
| Protocols | `{Feature}ServiceProtocol` | `MedicationServiceProtocol` |
| Models | Noun, singular | `Medication`, `DoseLog` |
| Mocks | `Mock{Service}` | `MockMedicationService` |
| Tests | `{Class}Tests` | `MedicationsViewModelTests` |

---

## Key Files Quick Reference

| File | Purpose |
|------|---------|
| `App/AppDependencies.swift` | **Only place** to register services into DI |
| `Core/DI/DIContainer.swift` | DI container — do not modify unless adding features |
| `Core/Network/OpenFDAEndpoint.swift` | Add/modify openFDA endpoints here |
| `Core/Storage/CoreDataStack.swift` | CoreData singleton — inject in tests via `inMemory: true` |
| `Modules/Settings/ViewModels/SettingsViewModel.swift` | Text size / language / dark mode state |
| `Shared/Utilities/LocalizationManager.swift` | Runtime language switching |
| `Shared/Constants/AppConstants.swift` | Magic numbers, keys, URLs |

---

*Last updated: Phase 1 complete — 2026-03-28*
