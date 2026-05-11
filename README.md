# PillPath — Medication Management iOS Application

| | |
|---|---|
| **Batch** | BSc Hons in Computing 2024.2P |
| **Module** | iOS Development |
| **Coursework** | Individual |
| **Student Name** | B N D U Fernando |
| **NIBM Student Index** | COBSCCOMP24.2P-035 |
| **Coventry Student Index** | 16110658 |

---

## Introduction

PillPath is a native iOS application designed to help users manage their medications, track dose adherence, and maintain a record of medical events. The app targets individuals managing complex medication schedules and supports multiple users on the same device with complete data isolation.

The system handles the full medication lifecycle: adding medications (manually or via FDA drug lookup and OCR scan), scheduling doses, logging adherence, recording medical events, and generating insights from historical data. All data is stored locally using CoreData for offline-first performance, with Firebase Authentication providing secure multi-user identity.

---

## Core Features

- **Multi-Method Authentication** — Email/password with email verification, Google SSO, Phone OTP, and Face ID / Touch ID lock
- **Medication Management** — Add medications manually, search the OpenFDA drug database, or scan a prescription label using OCR
- **Dose Scheduling** — Daily, interval-based, specific days, or custom frequency schedules with configurable dose times
- **Dose Tracking** — Mark doses as taken, skipped, or missed; automatic missed-dose detection after a one-hour grace window
- **Medical Events** — Log doctor visits, tests, and notes with optional links to related medications
- **Adherence Insights** — Weekly and monthly adherence rate, per-medication performance, and streak tracking
- **Multi-User Isolation** — All CoreData queries are scoped to the signed-in user's Firebase UID; switching accounts shows completely separate data
- **Biometric App Lock** — Face ID / Touch ID gate on app relaunch; biometric restores the Firebase Keychain session without re-entering credentials
- **Emergency Contact & Guardian** — Store emergency contact details; guardian notification architecture documented for future FCM integration
- **Accessibility** — Adjustable text size, high-contrast mode, and full VoiceOver support

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Local Database | CoreData / SQLite |
| Authentication | Firebase Authentication |
| Google Sign-In | GoogleSignIn iOS SDK |
| Drug Lookup | OpenFDA REST API |
| OCR | Vision framework (on-device) |
| Biometrics | LocalAuthentication framework |
| Calendar Integration | EventKit |
| Notifications | UserNotifications framework |
| Dependency Injection | Custom DIContainer (protocol-based) |
| Minimum Deployment | iOS 17.0 |

---

## Architecture

PillPath follows a layered MVVM architecture with protocol-based dependency injection.

```
PillPath/
├── App/
│   ├── PillPathApp.swift          App entry point — Firebase configure, DI registration
│   ├── RootView.swift             Auth gate — routes to WelcomeView, LoginView (locked), or MainTabContainer
│   └── AppDependencies.swift      DIContainer registrations
├── Core/
│   ├── AppSession.swift           Singleton holding current Firebase UID for CoreData scoping
│   ├── DI/                        DIContainer and protocol registrations
│   ├── Network/                   NetworkClient and endpoint definitions (OpenFDA)
│   └── Storage/
│       ├── CoreDataStack.swift    NSPersistentContainer with lightweight migration enabled
│       ├── Entities/              NSManagedObject subclasses (+CoreDataClass / +CoreDataProperties)
│       └── Mappers/               Bidirectional entity ↔ domain model mappers
├── Modules/
│   ├── Authentication/            FirebaseAuthService, AuthViewModel, all auth views
│   ├── Home/                      Today's schedule, CalendarStrip, dose item rows
│   ├── Medications/               Add/edit medication, OpenFDA lookup, OCR scan
│   ├── Scheduling/                Schedule management, dose tracking, events, activity feed
│   ├── Insights/                  Adherence charts, per-medication stats, tips
│   ├── Settings/                  SettingsViewModel, all settings views
│   ├── OCR/                       Vision-based label scanning
│   └── Lookup/                    OpenFDA search and detail
└── Shared/
    ├── Components/                AppModal, PrimaryButton, AuthTextField, etc.
    ├── Theme/                     AppFont, AppSpacing, AppRadius, Color extensions
    └── Constants/                 App-wide constants
```

---

## Project Setup

### Prerequisites

| Tool | Version / Notes |
|---|---|
| Xcode | 16.0 or later |
| iOS Simulator | iOS 17.0+ |
| CocoaPods | Not used — Swift Package Manager only |
| Firebase account | Free Spark plan is sufficient |
| Google Cloud Console | Required for Google Sign-In OAuth client |

---

### 1. Clone the Repository

```bash
git clone https://github.com/Dilshan-Fernando-01/PillPath.git
cd PillPath
```

---

### 2. Open in Xcode

```bash
open PillPath/PillPath.xcodeproj
```

Xcode will automatically resolve Swift Package Manager dependencies on first open. Wait for the package resolution to complete before building.

**Swift Package dependencies (resolved automatically):**

| Package | Products Used |
|---|---|
| `firebase-ios-sdk` | FirebaseAuth, FirebaseCore, FirebaseStorage |
| `GoogleSignIn-iOS` | GoogleSignIn, GoogleSignInSwift |

---

### 3. Firebase Setup

PillPath requires a Firebase project with Authentication enabled.

#### 3.1 Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → name it (e.g. `pillpath`)
3. Disable Google Analytics if not needed → **Create project**

#### 3.2 Register the iOS App

1. In your Firebase project → **Add app** → iOS
2. **iOS bundle ID:** `com.dilshan.PillPath`
3. Click through the remaining steps
4. **Download `GoogleService-Info.plist`**

#### 3.3 Add the Plist to Xcode

> ⚠️ **Never commit `GoogleService-Info.plist` to a public repository.** The file contains an API key that will be flagged by GitHub secret scanning.

1. Drag `GoogleService-Info.plist` into the `PillPath/` folder inside Xcode (the folder containing `PillPathApp.swift`)
2. Ensure **"Add to targets: PillPath"** is checked
3. Verify the file appears under the `PillPath` target in the Xcode file navigator

The file is listed in `.gitignore` — it will not be tracked by git.

#### 3.4 Enable Authentication Providers

In Firebase Console → **Authentication** → **Sign-in method**:

| Provider | Action |
|---|---|
| Email/Password | Enable |
| Google | Enable — this auto-creates an OAuth 2.0 client |
| Phone | Enable — add test numbers for simulator: `+1 650-555-0000` / code `123456` |

#### 3.5 Google Sign-In URL Scheme

1. Open `GoogleService-Info.plist` and copy the value of `REVERSED_CLIENT_ID`
   (format: `com.googleusercontent.apps.XXXXXXX-XXXXXXX`)
2. In Xcode → select the **PillPath** target → **Info** tab → **URL Types**
3. Add a new entry:
   - **Identifier:** `com.google.GIDSignIn`
   - **URL Schemes:** paste the `REVERSED_CLIENT_ID` value

Without this URL scheme, Google Sign-In will not return to the app after the browser authentication step.

---

### 4. Build and Run

1. Select a simulator running iOS 17.0 or later (or a connected device)
2. Press **⌘R** to build and run

The app will launch on the Welcome screen. Register with an email address — Firebase will send a verification email before granting access.

---

### 5. Test Authentication Methods

#### Email / Password
- Register → check email for verification link → tap link → return to app → sign in

#### Google Sign-In
- Tap **Continue with Google** on the Login or Register screen
- The system browser opens the Google OAuth consent page
- After authorising, the app resumes and the user is signed in

#### Phone OTP (Simulator)
- Use the Firebase test number: `+1 650-555-0000`
- Verification code: `123456`
- Real SMS delivery requires a physical device

#### Face ID (Simulator)
- Enable Face ID in Settings (inside PillPath) → toggle **Enable Face ID / Touch ID Lock**
- In the iOS Simulator menu bar: **Features → Face ID → Enroll**
- Sign out and reopen the app — the Face ID card appears on the login screen
- **Features → Face ID → Matching Face** to simulate a successful scan

---

## Multi-User Data Isolation

Every CoreData entity (`MedicationEntity`, `MedicalEventEntity`) carries an optional `userId` attribute populated from `AppSession.shared.currentUserId`, which is set to `Auth.auth().currentUser?.uid` at sign-in.

All service fetch methods include a predicate:

```swift
NSPredicate(format: "userId == %@", AppSession.shared.currentUserId)
```

Signing out clears the local `currentUser` but keeps the Firebase Keychain session alive so biometric can restore it on the next open. Signing in as a different user replaces the Firebase session automatically, and `AppSession.currentUserId` updates via `didSet` on `AuthViewModel.currentUser`.

---

## Key Screens

| Screen | Description |
|---|---|
| Welcome | App intro with Sign In / Register entry points |
| Login | Email/password, Google SSO, Phone, Face ID, Forgot Password |
| Register | Name, email, password with strength indicator and Google SSO |
| Email Verification | Step-by-step instructions with 60 s resend cooldown |
| Home | Today's doses grouped by time of day, next-dose card, calendar strip |
| Add Medication | 5-step flow: search/scan → details → schedule → times → stock |
| Activity | Three-tab view: Schedule (dose list), Medications (active list), Events |
| Insights | Adherence rate, weekly bar chart, per-medication performance |
| Settings | Biometric lock, notifications, text size, high contrast, emergency contact, sign out |

---

## Known Simulator Limitations

| Feature | Simulator Behaviour |
|---|---|
| Phone OTP (real SMS) | Use Firebase test number `+1 650-555-0000` + code `123456` |
| Face ID | Must manually enrol via **Features → Face ID → Enrolled** and trigger via **Matching/Non-matching Face** |
| Camera OCR scan | Camera not available in simulator; use **Photo Library** source instead |
| Push Notifications | APNs delivery not supported in simulator |

---

## Security Notes

- `GoogleService-Info.plist` is excluded from version control via `.gitignore`
- `NSFaceIDUsageDescription` is declared in `Info.plist` as required by Apple
- All CoreData queries return zero results when no user is signed in (`userId` guard returns early)
- Firebase session tokens are stored in the iOS Keychain by the Firebase SDK (not UserDefaults)
- Email sign-in requires verified email before any session is granted
