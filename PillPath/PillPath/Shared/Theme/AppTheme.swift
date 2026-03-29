//
//  AppTheme.swift
//  PillPath
//
//  Single source of truth for all design tokens extracted from the Figma designs.
//  Use AppTheme.* everywhere — never hardcode hex values in views.
//

import SwiftUI
import UIKit

// MARK: - UIColor hex helper for dynamic colours

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8)  & 0xFF) / 255
        let b = CGFloat( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

private extension Color {
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

// MARK: - Color Palette

extension Color {
    // Brand (intentionally same in light + dark)
    static let brandPrimary      = Color(hex: "#2B5CE6")
    static let brandAccent       = Color(hex: "#3D72F6")
    static let brandPrimaryLight = dynamic(light: "#EEF2FF", dark: "#1E2A66")

    // Neutrals
    static let appBackground  = dynamic(light: "#F5F6FA", dark: "#0B0B1E")
    static let appSurface     = dynamic(light: "#FFFFFF", dark: "#16163A")
    static let appBorder      = dynamic(light: "#E4E9F2", dark: "#2A2A5C")

    // Text
    static let textPrimary    = dynamic(light: "#0D0D2B", dark: "#F0F0FF")
    static let textSecondary  = dynamic(light: "#8F9BB3", dark: "#8090B8")
    static let textDisabled   = dynamic(light: "#C5CEE0", dark: "#4A4A7A")

    // Semantic (same in both modes — high visibility)
    static let semanticSuccess  = Color(hex: "#28A745")
    static let semanticWarning  = Color(hex: "#FFC107")
    static let semanticError    = Color(hex: "#DC3545")
    static let semanticInfo     = Color(hex: "#17A2B8")

    // Gradients
    static let gradientStart  = Color(hex: "#2B5CE6")
    static let gradientEnd    = Color(hex: "#6C8FFF")
}

// MARK: - Global font scale (updated by SettingsViewModel on init + didSet)

var appFontScale: CGFloat = 1.0

// MARK: - Typography

enum AppFont {
    static func largeTitle() -> Font { .system(size: 28 * appFontScale, weight: .bold, design: .default) }
    static func title()      -> Font { .system(size: 22 * appFontScale, weight: .semibold) }
    static func headline()   -> Font { .system(size: 17 * appFontScale, weight: .semibold) }
    static func body()       -> Font { .system(size: 15 * appFontScale, weight: .regular) }
    static func subheadline()-> Font { .system(size: 13 * appFontScale, weight: .regular) }
    static func caption()    -> Font { .system(size: 11 * appFontScale, weight: .regular) }
    static func label()      -> Font { .system(size: 11 * appFontScale, weight: .medium) }
}

// MARK: - Spacing & Radius

enum AppSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

enum AppRadius {
    static let sm:    CGFloat = 8
    static let md:    CGFloat = 12
    static let lg:    CGFloat = 16
    static let xl:    CGFloat = 24
    static let full:  CGFloat = 100  // pill shape
}

// MARK: - High-contrast colour override

/// Set to true when SettingsViewModel.highContrastMode is on.
var appHighContrast: Bool = false

extension Color {
    /// Use in place of textSecondary for improved contrast when enabled.
    static var adaptiveTextSecondary: Color {
        appHighContrast ? Color(hex: "#3A3A5C") : Color.textSecondary
    }
    /// Use in place of appBorder for improved contrast when enabled.
    static var adaptiveBorder: Color {
        appHighContrast ? Color(hex: "#8F9BB3") : Color.appBorder
    }
}

// MARK: - Shadow

extension View {
    func appCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    func appButtonShadow() -> some View {
        self.shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Hex Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
