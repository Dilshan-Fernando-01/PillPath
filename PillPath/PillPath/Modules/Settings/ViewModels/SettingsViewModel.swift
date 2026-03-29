//
//  SettingsViewModel.swift
//  PillPath — Settings Module
//
//  Single source of truth for all user preferences.
//  Injected as @EnvironmentObject from PillPathApp.
//

import Foundation
import Combine
import SwiftUI

final class SettingsViewModel: ObservableObject {

    // MARK: - Security

    @Published var biometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricLockEnabled, forKey: Keys.biometricLock) }
    }

    // MARK: - Notifications

    @Published var medicationReminders: Bool {
        didSet { UserDefaults.standard.set(medicationReminders, forKey: Keys.medicationReminders) }
    }

    @Published var eventReminders: Bool {
        didSet { UserDefaults.standard.set(eventReminders, forKey: Keys.eventReminders) }
    }

    @Published var reminderSound: ReminderSound {
        didSet { UserDefaults.standard.set(reminderSound.rawValue, forKey: Keys.reminderSound) }
    }

    // MARK: - Emergency Contact

    @Published var emergencyContact: EmergencyContact? {
        didSet {
            if let contact = emergencyContact,
               let data = try? JSONEncoder().encode(contact) {
                UserDefaults.standard.set(data, forKey: Keys.emergencyContact)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.emergencyContact)
            }
        }
    }

    // MARK: - Accessibility

    @Published var textSize: AppTextSize {
        didSet {
            appFontScale = textSize.scaleFactor
            UserDefaults.standard.set(textSize.rawValue, forKey: Keys.textSize)
        }
    }

    @Published var highContrastMode: Bool {
        didSet {
            appHighContrast = highContrastMode
            UserDefaults.standard.set(highContrastMode, forKey: Keys.highContrast)
        }
    }

    // MARK: - Guardian

    @Published var guardianContact: GuardianContact? {
        didSet {
            if let g = guardianContact, let data = try? JSONEncoder().encode(g) {
                UserDefaults.standard.set(data, forKey: Keys.guardianContact)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.guardianContact)
            }
        }
    }

    // MARK: - General

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var colorScheme: AppColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme) }
    }

    // MARK: - App Info

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // MARK: - Init

    init() {
        let d = UserDefaults.standard

        self.biometricLockEnabled  = d.bool(forKey: Keys.biometricLock)
        self.medicationReminders   = d.object(forKey: Keys.medicationReminders) == nil ? true  : d.bool(forKey: Keys.medicationReminders)
        self.eventReminders        = d.object(forKey: Keys.eventReminders)       == nil ? true  : d.bool(forKey: Keys.eventReminders)
        self.reminderSound         = ReminderSound(rawValue: d.string(forKey: Keys.reminderSound) ?? "") ?? .chime
        self.textSize              = AppTextSize(rawValue: d.string(forKey: Keys.textSize) ?? "") ?? .medium
        self.highContrastMode      = d.bool(forKey: Keys.highContrast)
        self.language              = AppLanguage(rawValue: d.string(forKey: Keys.language) ?? "") ?? .english
        self.colorScheme           = AppColorScheme(rawValue: d.string(forKey: Keys.colorScheme) ?? "") ?? .system

        if let data    = d.data(forKey: Keys.emergencyContact),
           let contact = try? JSONDecoder().decode(EmergencyContact.self, from: data) {
            self.emergencyContact = contact
        }

        if let data    = d.data(forKey: Keys.guardianContact),
           let guardian = try? JSONDecoder().decode(GuardianContact.self, from: data) {
            self.guardianContact = guardian
        }

        // Seed globals so AppFont / contrast colours are correct on first render
        appFontScale    = self.textSize.scaleFactor
        appHighContrast = self.highContrastMode
    }

    // MARK: - Keys

    private enum Keys {
        static let biometricLock        = "pp_biometric_lock"
        static let medicationReminders  = "pp_med_reminders"
        static let eventReminders       = "pp_event_reminders"
        static let reminderSound        = "pp_reminder_sound"
        static let emergencyContact     = "pp_emergency_contact"
        static let textSize             = "pp_text_size"
        static let highContrast         = "pp_high_contrast"
        static let language             = "pp_language"
        static let colorScheme          = "pp_color_scheme"
        static let guardianContact      = "pp_guardian_contact"
    }
}

// MARK: - ReminderSound

enum ReminderSound: String, CaseIterable, Identifiable {
    case chime   = "chime"
    case bell    = "bell"
    case alert   = "alert"
    case silent  = "silent"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chime:  return "Chime"
        case .bell:   return "Bell"
        case .alert:  return "Alert"
        case .silent: return "Silent"
        }
    }
}
