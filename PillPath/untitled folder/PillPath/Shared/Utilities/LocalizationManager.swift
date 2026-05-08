

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


func L(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}
