//
//  ActivityMedicationsTab.swift
//  PillPath — Scheduling Module
//
//  Tab 2: Ongoing Medications + Stopped Medications + Prescription Records.
//  Uses MedicationActionsSheet for edit / toggle / delete.
//

import SwiftUI

struct ActivityMedicationsTab: View {

    @ObservedObject var viewModel: ActivityViewModel
    @State private var sheetMedication: Medication?
    @State private var editViewModel: AddMedicationViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {

                // Search bar
                searchBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                // Ongoing
                medicationSection(
                    title: "Ongoing",
                    icon: "checkmark.circle.fill",
                    iconColor: Color.semanticSuccess,
                    medications: viewModel.filteredActiveMedications,
                    countBadge: viewModel.filteredActiveMedications.count
                )

                // Stopped
                if !viewModel.stoppedMedications.isEmpty {
                    medicationSection(
                        title: "Stopped",
                        icon: "pause.circle.fill",
                        iconColor: Color.textSecondary,
                        medications: viewModel.filteredStoppedMedications,
                        countBadge: nil
                    )
                }

                // Prescription Records placeholder
                prescriptionRecordsSection

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
        }
        .background(Color.appBackground)
        .sheet(item: $sheetMedication) { med in
            MedicationActionsSheet(
                medication: med,
                onViewDetails: {
                    // Capture id before sheet dismisses
                    let captured = med
                    sheetMedication = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editViewModel = AddMedicationViewModel.editing(medication: captured)
                    }
                },
                onToggleActive: { change in
                    viewModel.toggleActive(med, change: change)
                    sheetMedication = nil
                },
                onDelete: {
                    viewModel.deleteMedication(med)
                    sheetMedication = nil
                },
                onDismiss: { sheetMedication = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $editViewModel) { vm in
            AddMedicationFlowView(viewModel: vm)
                .onDisappear { viewModel.loadMedications() }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            TextField("Search medications...", text: $viewModel.medicationSearch)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
            if !viewModel.medicationSearch.isEmpty {
                Button { viewModel.medicationSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
    }

    // MARK: - Medication Section

    private func medicationSection(
        title: String,
        icon: String,
        iconColor: Color,
        medications: [Medication],
        countBadge: Int?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Section header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                if let count = countBadge {
                    Text("\(count)")
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                }
                Spacer()
            }

            if medications.isEmpty {
                Text("None")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
                    .padding(.vertical, AppSpacing.sm)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(medications) { med in
                        ActivityMedicationRow(medication: med)
                            .onTapGesture { sheetMedication = med }
                    }
                }
            }
        }
    }

    // MARK: - Prescription Records

    private var prescriptionRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.brandPrimary)
                Text("Prescription Records")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }

            HStack(spacing: AppSpacing.md) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.brandPrimary.opacity(0.6))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scanned prescriptions appear here")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Text("Use the scan tab to import a prescription")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }
}

// MARK: - Activity Medication Row

struct ActivityMedicationRow: View {

    let medication: Medication

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 44, height: 44)
                Image(systemName: medication.form.systemIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.brandPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(medication.name)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    if let display = medication.displayName {
                        Text("(\(display))")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Text(medication.dosageDisplay)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                if !medication.isActive, let sc = medication.statusChange {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.semanticError)
                        Text("Stopped · \(sc.reason)")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.semanticError)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }
}
