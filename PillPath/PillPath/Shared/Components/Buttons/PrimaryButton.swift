//
//  PrimaryButton.swift
//  PillPath — Design System
//
//  Full-width blue button with arrow, matches Figma "Next →" / "Next Step →" / "Save Medication"
//

import SwiftUI

struct PrimaryButton: View {

    let title: String
    var icon: String?          // SF Symbol name, e.g. "arrow.right"
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView().progressViewStyle(.circular).tint(.white)
                } else {
                    Text(title)
                        .font(AppFont.headline())
                        .foregroundStyle(.white)
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isDisabled ? Color.textDisabled : Color.brandPrimary)
            .clipShape(Capsule())
            .appButtonShadow()
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Next", icon: "arrow.right") { }
        PrimaryButton(title: "Next Step", icon: "arrow.right") { }
        PrimaryButton(title: "Save Medication") { }
        PrimaryButton(title: "Loading", isLoading: true) { }
        PrimaryButton(title: "Disabled", isDisabled: true) { }
    }
    .padding()
    .background(Color.appBackground)
}
