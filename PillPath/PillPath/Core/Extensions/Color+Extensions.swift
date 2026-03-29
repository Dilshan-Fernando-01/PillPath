//
//  Color+Extensions.swift
//  PillPath
//
//  App-wide semantic colors. All colors should come from here,
//  not from hardcoded hex values in views.
//

import SwiftUI

extension Color {
    // Brand
    static let pillPrimary   = Color("PillPrimary",   bundle: .main)
    static let pillSecondary = Color("PillSecondary", bundle: .main)
    static let pillAccent    = Color("PillAccent",    bundle: .main)

    // Semantic
    static let pillBackground = Color("PillBackground", bundle: .main)
    static let pillSurface    = Color("PillSurface",    bundle: .main)
    static let pillError      = Color("PillError",      bundle: .main)
    static let pillSuccess    = Color("PillSuccess",    bundle: .main)
    static let pillWarning    = Color("PillWarning",    bundle: .main)
}
