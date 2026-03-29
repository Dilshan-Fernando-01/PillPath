//
//  AppSettings.swift
//  PillPath — Settings Module
//
//  All user preferences persisted via UserDefaults.
//  Injected at root so every view can read them via @EnvironmentObject.
//

import Foundation
import SwiftUI

/// Supported app languages.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english  = "en"
    case sinhala  = "si"
    case tamil    = "ta"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .sinhala: return "සිංහල"
        case .tamil:   return "தமிழ்"
        }
    }
}

/// Dynamic text scaling options.
enum AppTextSize: String, CaseIterable, Identifiable {
    case small  = "small"
    case medium = "medium"
    case large  = "large"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    /// Scale factor applied to base font sizes.
    var scaleFactor: CGFloat {
        switch self {
        case .small:  return 0.85
        case .medium: return 1.0
        case .large:  return 1.2
        }
    }
}

// MARK: - Guardian Contact

struct GuardianContact: Codable, Equatable {
    var name: String
    var phoneNumber: String
    var notifyOnMedTaken: Bool
    var notifyOnMedMissed: Bool
    var notifyOnEvents: Bool

    var callURL: URL? {
        let digits = phoneNumber.filter(\.isNumber)
        return URL(string: "tel://\(digits)")
    }
}

/// Preferred colour scheme.
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
