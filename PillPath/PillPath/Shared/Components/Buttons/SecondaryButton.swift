//
//  SecondaryButton.swift
//  PillPath — Design System
//
//  Outlined button, matches Figma "Back" button style.
//

import SwiftUI

struct SecondaryButton: View {

    let title: String
    var icon: String?
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    Image(systemName: icon).fontWeight(.semibold)
                }
                Text(title).font(AppFont.headline())
            }
            .foregroundStyle(isDisabled ? Color.textDisabled : Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appSurface)
            .overlay(
                Capsule()
                    .stroke(isDisabled ? Color.textDisabled : Color.brandPrimary, lineWidth: 1.5)
            )
            .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Back", icon: "chevron.left") { }
        SecondaryButton(title: "Scan Another") { }
    }
    .padding()
    .background(Color.appBackground)
}
