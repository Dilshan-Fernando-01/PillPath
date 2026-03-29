//
//  AppConstants.swift
//  PillPath
//

import Foundation

enum AppConstants {

    enum API {
        static let openFDABaseURL = "https://api.fda.gov"
        static let openFDADefaultLimit = 10
    }

    enum Notifications {
        static let medicationReminderCategory = "MEDICATION_REMINDER"
        static let doseReminderAction         = "DOSE_REMINDER"
    }

    enum Storage {
        static let coreDataModelName = "PillPath"
    }

    enum UserDefaultsKeys {
        static let onboardingComplete = "pillpath_onboarding_complete"
        static let lastSyncDate       = "pillpath_last_sync_date"
    }

    enum UI {
        static let cornerRadius: CGFloat   = 12
        static let cardPadding: CGFloat    = 16
        static let sectionSpacing: CGFloat = 24
    }
}
