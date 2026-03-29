//
//  LocalizationManager.swift
//  PillPath
//
//  Wraps NSLocalizedString with app language support.
//  Observe SettingsViewModel.language and call LocalizationManager.setLanguage(_:)
//  to switch language at runtime without restarting the app.
//

import Foundation

final class LocalizationManager {

    static let shared = LocalizationManager()
    private var bundle: Bundle = .main

    private init() {}

    func setLanguage(_ language: AppLanguage) {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            bundle = .main
            return
        }
        bundle = languageBundle
    }

    func localized(_ key: String, comment: String = "") -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// MARK: - Convenience global function

func L(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}
