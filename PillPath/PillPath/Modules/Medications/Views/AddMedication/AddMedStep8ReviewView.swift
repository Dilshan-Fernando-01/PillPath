//
//  AddMedStep8ReviewView.swift
//  PillPath — Medications Module
//
//  Step 8: Full review of all entered information.
//  Each section has an Edit button that jumps back to that step.
//

import SwiftUI

struct AddMedStep8ReviewView: View {

    @ObservedObject var viewModel: AddMedicationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "Review your medication",
                subtitle: "Check the details below. Tap Edit to make any changes."
            )

            // Medication summary card
            medicationCard

            // Schedule card
            scheduleCard

            // Timing card
            timingCard

            // Advanced card (only non-empty fields)
            advancedCard

            Spacer()
        }
    }

    // MARK: - Medication Card

    private var medicationCard: some View {
        reviewSection(title: "Medication", step: 1) {
            reviewRow(icon: "pills", label: "Name", value: viewModel.medicationName)
            Divider().padding(.leading, 44)
            reviewRow(icon: viewModel.selectedForm.systemIcon, label: "Form", value: viewModel.selectedForm.displayName)
            Divider().padding(.leading, 44)
            reviewRow(icon: "number", label: "Dosage", value: viewModel.dosageDisplay)
            if !viewModel.displayName.isEmpty {
                Divider().padding(.leading, 44)
                reviewRow(icon: "tag", label: "Display Name", value: viewModel.displayName)
            }
        }
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        reviewSection(title: "Schedule", step: 4) {
            reviewRow(icon: "calendar", label: "Frequency", value: viewModel.frequencySummary)
            Divider().padding(.leading, 44)
            reviewRow(icon: "clock", label: "Time(s)", value: viewModel.timeSummary)
            Divider().padding(.leading, 44)
            reviewRow(icon: "fork.knife", label: "Meal Timing", value: viewModel.mealTiming.displayName)
        }
    }

    // MARK: - Timing Card

    private var timingCard: some View {
        reviewSection(title: "Duration", step: 7) {
            reviewRow(
                icon: "calendar.badge.clock",
                label: "Start",
                value: viewModel.startDate.formatted(.dateTime.day().month().year())
            )
            if !viewModel.isOngoing {
                Divider().padding(.leading, 44)
                reviewRow(
                    icon: "calendar.badge.minus",
                    label: "End",
                    value: viewModel.endDate.formatted(.dateTime.day().month().year())
                )
            } else {
                Divider().padding(.leading, 44)
                reviewRow(icon: "infinity", label: "Duration", value: "Ongoing")
            }
            Divider().padding(.leading, 44)
            reviewRow(
                icon: "bell",
                label: "Reminders",
                value: viewModel.doseReminders ? viewModel.notificationOffset.displayName : "Off"
            )
        }
    }

    // MARK: - Advanced Card

    @ViewBuilder
    private var advancedCard: some View {
        let qty = Int(viewModel.currentQuantity) ?? 0
        let hasAdvanced = qty > 0 || !viewModel.notes.isEmpty

        if hasAdvanced {
            reviewSection(title: "Advanced", step: 7) {
                if qty > 0 {
                    reviewRow(icon: "shippingbox", label: "Qty", value: "\(qty) \(viewModel.dosageUnit.displayName)")
                }
                if !viewModel.notes.isEmpty {
                    if qty > 0 { Divider().padding(.leading, 44) }
                    reviewRow(icon: "note.text", label: "Notes", value: viewModel.notes)
                }
            }
        }
    }

    // MARK: - Review Section

    private func reviewSection<Content: View>(
        title: String,
        step: Int,
        @ViewBuilder rows: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                SectionLabel(text: title)
                Spacer()
                Button {
                    viewModel.goToStep(step)
                } label: {
                    Text("Edit")
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.brandPrimaryLight)
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 0) {
                rows()
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }

    // MARK: - Review Row

    private func reviewRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 20)

            Text(label)
                .font(AppFont.subheadline())
                .foregroundStyle(Color.textSecondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(AppFont.subheadline())
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }
}
