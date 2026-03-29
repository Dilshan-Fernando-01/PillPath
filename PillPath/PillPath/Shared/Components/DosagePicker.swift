//
//  DosagePicker.swift
//  PillPath — Design System
//
//  Step 3: large dosage number + quick-select chips (0.5, 1, 1.5, 2).
//  Matches Figma "What is the dosage?" screen.
//

import SwiftUI

struct DosagePicker: View {
    @Binding var amount: Double
    @Binding var unit: DosageUnit

    private let quickValues: [Double] = [0.5, 1, 1.5, 2]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Unit toggle (Tablet | Liquid)
            HStack(spacing: 0) {
                unitToggle(label: "Tablet", unit: .pills)
                unitToggle(label: "Liquid", unit: .ml)
            }
            .background(Color.appBackground)
            .clipShape(Capsule())

            // Large dosage display
            HStack(alignment: .lastTextBaseline, spacing: AppSpacing.sm) {
                Text(amountText)
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.25), value: amount)

                Text(unit.displayName)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)

            // Quick-select chips
            HStack(spacing: AppSpacing.md) {
                ForEach(quickValues, id: \.self) { value in
                    quickChip(value: value)
                }
            }
        }
    }

    // MARK: - Sub-views

    private func unitToggle(label: String, unit: DosageUnit) -> some View {
        let isSelected = self.unit == unit
        return Button(label) { self.unit = unit }
            .font(AppFont.subheadline())
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.appSurface : Color.clear)
            .clipShape(Capsule())
            .padding(4)
    }

    private func quickChip(value: Double) -> some View {
        let isSelected = amount == value
        return Button(action: { withAnimation { amount = value } }) {
            Text(chipLabel(value))
                .font(AppFont.body())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.brandPrimary : Color.textPrimary)
                .frame(width: 60, height: 44)
                .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var amountText: String {
        amount.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(amount)) : String(amount)
    }

    private func chipLabel(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

#Preview {
    @State var amount: Double = 1
    @State var unit: DosageUnit = .pills
    return DosagePicker(amount: $amount, unit: $unit)
        .padding()
        .background(Color.appBackground)
}
