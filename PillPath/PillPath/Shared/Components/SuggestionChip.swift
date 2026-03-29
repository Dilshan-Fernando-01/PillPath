//
//  SuggestionChip.swift
//  PillPath — Design System
//
//  Small rounded suggestion chips shown below the medication name field.
//  Matches Figma Step 1: "Aspirin", "Paracetamol", "Amoxicillin".
//

import SwiftUI

struct SuggestionChip: View {
    let label: String
    var isSelected: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(AppFont.subheadline())
                .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SuggestionChipsRow: View {
    let suggestions: [String]
    @Binding var selected: String?
    var onSelect: (String) -> Void = { _ in }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(
                        label: suggestion,
                        isSelected: selected == suggestion
                    ) {
                        selected = suggestion
                        onSelect(suggestion)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}

#Preview {
    @State var selected: String? = "Aspirin"
    return SuggestionChipsRow(
        suggestions: ["Aspirin", "Paracetamol", "Amoxicillin", "Ibuprofen"],
        selected: $selected
    )
    .background(Color.appBackground)
}
