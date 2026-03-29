//
//  View+Extensions.swift
//  PillPath
//

import SwiftUI

extension View {

    /// Apply the app's dynamic text scaling based on AppSettings.
    func pillPathFont(_ style: Font.TextStyle) -> some View {
        self.font(Font.system(style))
    }

    /// Hide the view conditionally without removing it from the hierarchy.
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide { self.hidden() } else { self }
    }
}
