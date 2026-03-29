//
//  AddMedStep6MealView.swift
//  PillPath — Medications Module
//
//  Step 6: Select meal timing preference.
//

import SwiftUI

struct AddMedStep6MealView: View {

    @ObservedObject var viewModel: AddMedicationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "Should it be taken with food?",
                subtitle: "Select the meal timing as instructed by your doctor."
            )

            // Shared segmented selector + detail rows
            MealTimingSelector(selected: $viewModel.mealTiming)

            // "No preference" option
            noPreferenceRow

            Spacer()
        }
    }

    // MARK: - No Preference

    private var noPreferenceRow: some View {
        let isSelected = viewModel.mealTiming == .none
        return Button {
            withAnimation { viewModel.mealTiming = .none }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "circle.dashed")
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("No Preference")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text("No specific meal requirement")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brandPrimary)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.textSecondary)
                        .font(.system(size: 14))
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
