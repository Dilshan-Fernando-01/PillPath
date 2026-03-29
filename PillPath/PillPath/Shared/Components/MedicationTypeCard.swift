//
//  MedicationTypeCard.swift
//  PillPath — Design System
//
//  Selectable card used in Step 2 (medication type grid).
//  Matches Figma: icon circle + label, blue border when selected.
//

import SwiftUI

struct MedicationTypeCard: View {

    let form: MedicationForm
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 60, height: 60)
                    Image(systemName: form.systemIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                }
                Text(form.displayName)
                    .font(AppFont.subheadline())
                    .foregroundStyle(Color.textPrimary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Usage Example

struct MedicationTypeGrid: View {
    @Binding var selected: MedicationForm

    private let items: [MedicationForm] = [.tablet, .capsule, .liquid, .injection]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            ForEach(items) { form in
                MedicationTypeCard(form: form, isSelected: selected == form) {
                    selected = form
                }
            }
        }
    }
}

#Preview {
    @State var selected: MedicationForm = .tablet
    return MedicationTypeGrid(selected: $selected)
        .padding()
        .background(Color.appBackground)
}
