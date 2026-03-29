//
//  AddMedStep3DosageView.swift
//  PillPath — Medications Module
//
//  Step 3: Set dosage amount + unit.
//  Uses the shared DosagePicker component + a custom amount entry.
//

import SwiftUI

struct AddMedStep3DosageView: View {

    @ObservedObject var viewModel: AddMedicationViewModel
    @State private var showCustomEntry = false
    @State private var customAmountText = ""
    @FocusState private var customFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "What is the dosage?",
                subtitle: "Enter the amount you take per dose."
            )

            // Shared dosage picker (quick chips + unit toggle)
            DosagePicker(amount: $viewModel.dosageAmount, unit: $viewModel.dosageUnit)
                .padding(.vertical, AppSpacing.md)

            // Custom amount entry
            if showCustomEntry {
                customAmountField
            } else {
                Button {
                    customAmountText = ""
                    showCustomEntry = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15))
                        Text("Enter custom amount")
                            .font(AppFont.subheadline())
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.brandPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }

            // Unit selector — all 3 units as pills
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionLabel(text: "Unit")
                HStack(spacing: AppSpacing.sm) {
                    ForEach(DosageUnit.allCases) { unit in
                        unitChip(unit)
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Custom Amount Field

    private var customAmountField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Custom Amount")
                .font(AppFont.subheadline())
                .foregroundStyle(Color.textSecondary)

            HStack {
                TextField("e.g. 2.5", text: $customAmountText)
                    .keyboardType(.decimalPad)
                    .font(AppFont.body())
                    .focused($customFocused)

                if !customAmountText.isEmpty {
                    Button("Apply") {
                        if let val = Double(customAmountText), val > 0 {
                            withAnimation { viewModel.dosageAmount = val }
                        }
                        showCustomEntry = false
                    }
                    .font(AppFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
                }

                Button {
                    showCustomEntry = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(customFocused ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
            )
        }
        .onAppear { customFocused = true }
    }

    // MARK: - Unit Chip

    private func unitChip(_ unit: DosageUnit) -> some View {
        let isSelected = viewModel.dosageUnit == unit
        return Button {
            viewModel.dosageUnit = unit
        } label: {
            Text(unit.displayName)
                .font(AppFont.subheadline())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 8)
                .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
