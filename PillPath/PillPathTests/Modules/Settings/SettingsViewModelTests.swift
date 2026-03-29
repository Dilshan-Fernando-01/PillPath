//
//  SettingsViewModelTests.swift
//  PillPathTests
//

import XCTest
@testable import PillPath

final class SettingsViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clean UserDefaults before each test
        let keys = ["pillpath_language", "pillpath_text_size", "pillpath_color_scheme"]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    func test_defaultValues() {
        let sut = SettingsViewModel()
        XCTAssertEqual(sut.language, .english)
        XCTAssertEqual(sut.textSize, .medium)
        XCTAssertEqual(sut.colorScheme, .system)
    }

    func test_language_persistsToUserDefaults() {
        let sut = SettingsViewModel()
        sut.language = .sinhala
        let stored = UserDefaults.standard.string(forKey: "pillpath_language")
        XCTAssertEqual(stored, AppLanguage.sinhala.rawValue)
    }

    func test_textSize_persistsToUserDefaults() {
        let sut = SettingsViewModel()
        sut.textSize = .large
        let stored = UserDefaults.standard.string(forKey: "pillpath_text_size")
        XCTAssertEqual(stored, AppTextSize.large.rawValue)
    }

    func test_colorScheme_persistsToUserDefaults() {
        let sut = SettingsViewModel()
        sut.colorScheme = .dark
        let stored = UserDefaults.standard.string(forKey: "pillpath_color_scheme")
        XCTAssertEqual(stored, AppColorScheme.dark.rawValue)
    }

    func test_restoredFromUserDefaults() {
        UserDefaults.standard.set(AppLanguage.tamil.rawValue, forKey: "pillpath_language")
        UserDefaults.standard.set(AppTextSize.large.rawValue,  forKey: "pillpath_text_size")
        UserDefaults.standard.set(AppColorScheme.dark.rawValue, forKey: "pillpath_color_scheme")

        let sut = SettingsViewModel()
        XCTAssertEqual(sut.language, .tamil)
        XCTAssertEqual(sut.textSize, .large)
        XCTAssertEqual(sut.colorScheme, .dark)
    }
}
