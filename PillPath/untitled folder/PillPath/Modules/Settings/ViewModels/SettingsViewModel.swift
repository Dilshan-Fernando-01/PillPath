

import Foundation
import Combine
import SwiftUI

final class SettingsViewModel: ObservableObject {



    @Published var biometricLockEnabled: Bool {
        didSet { UserDefaults.standard.set(biometricLockEnabled, forKey: Keys.biometricLock) }
    }



    @Published var medicationReminders: Bool {
        didSet { UserDefaults.standard.set(medicationReminders, forKey: Keys.medicationReminders) }
    }

    @Published var eventReminders: Bool {
        didSet { UserDefaults.standard.set(eventReminders, forKey: Keys.eventReminders) }
    }

    @Published var reminderSound: ReminderSound {
        didSet { UserDefaults.standard.set(reminderSound.rawValue, forKey: Keys.reminderSound) }
    }

  

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



    @Published var guardianContacts: [GuardianContact] {
        didSet {
            if let data = try? JSONEncoder().encode(guardianContacts) {
                UserDefaults.standard.set(data, forKey: Keys.guardianContacts)
            }
        }
    }


    var guardianContact: GuardianContact? { guardianContacts.first(where: { !$0.isEmpty }) }



    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    @Published var colorScheme: AppColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: Keys.colorScheme) }
    }



    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

   

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

    
        if let arrayData = d.data(forKey: Keys.guardianContacts),
           let contacts = try? JSONDecoder().decode([GuardianContact].self, from: arrayData) {
            self.guardianContacts = contacts
        } else if let legacyData = d.data(forKey: Keys.guardianContact),
                  let legacy = try? JSONDecoder().decode(GuardianContact.self, from: legacyData) {
          
            self.guardianContacts = [legacy]
            d.removeObject(forKey: Keys.guardianContact)
        } else {
            self.guardianContacts = []
        }

       
        appFontScale    = self.textSize.scaleFactor
        appHighContrast = self.highContrastMode
    }



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
        static let guardianContact      = "pp_guardian_contact"    // legacy key, kept for migration
        static let guardianContacts     = "pp_guardian_contacts"
    }
}


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
