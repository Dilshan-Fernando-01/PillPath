//
//  MedicationsListView.swift
//  PillPath — Medications Module
//
//  Medications list with Add Medication flow triggered via the + button.
//

import SwiftUI

struct MedicationsListView: View {

    @StateObject private var viewModel = MedicationsViewModel()
    @State private var showAddFlow = false
    @State private var searchText = ""
    @State private var selectedMedication: Medication?
    @State private var editViewModel: AddMedicationViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)

                    // Content
                    if viewModel.isLoading {
                        LoadingView(message: "Loading medications...")
                            .frame(maxHeight: .infinity)

                    } else if filteredMedications.isEmpty {
                        emptyState
                            .frame(maxHeight: .infinity)

                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.sm) {
                                ForEach(filteredMedications) { med in
                                    MedicationRowCard(medication: med) {
                                        viewModel.deleteMedication(med)
                                    }
                                    .onTapGesture {
                                        selectedMedication = med
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("My Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFlow = true
                    } label: {
                        Label("Add Medication", systemImage: "plus.circle.fill")
                            .font(AppFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFlow, onDismiss: {
            viewModel.loadMedications()
        }) {
            AddMedicationFlowView()
        }
        .sheet(item: $selectedMedication) { med in
            MedicationActionsSheet(
                medication: med,
                onViewDetails: {
                    let captured = med
                    selectedMedication = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editViewModel = AddMedicationViewModel.editing(medication: captured)
                    }
                },
                onToggleActive: { change in
                    viewModel.toggleActive(med, change: change)
                    selectedMedication = nil
                },
                onDelete: {
                    viewModel.deleteMedication(med)
                    selectedMedication = nil
                },
                onDismiss: { selectedMedication = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $editViewModel) { vm in
            AddMedicationFlowView(viewModel: vm)
                .onDisappear { viewModel.loadMedications() }
        }
        .onAppear { viewModel.loadMedications() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            TextField("Search medications…", text: $searchText)
                .font(AppFont.body())
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    // MARK: - Filtered List

    private var filteredMedications: [Medication] {
        guard !searchText.isEmpty else { return viewModel.medications }
        return viewModel.medications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.genericName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "cross.circle",
            title: "No Medications",
            subtitle: "Tap + to add your first medication.",
            actionLabel: "Add Medication"
        ) {
            showAddFlow = true
        }
    }
}

// MARK: - Medication Row Card

struct MedicationRowCard: View {

    let medication: Medication
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Form icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 48, height: 48)
                Image(systemName: medication.form.systemIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.brandPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
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
                HStack(spacing: AppSpacing.xs) {
                    Text(medication.dosageDisplay)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                    Text("•")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                    Text(medication.form.displayName)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
                // Status change details for inactive medications
                if !medication.isActive, let sc = medication.statusChange {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.semanticError)
                        Text("Stopped \(sc.formattedDate) · \(sc.reason)")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.semanticError)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Active indicator
            Circle()
                .fill(medication.isActive ? Color.semanticSuccess : Color.appBorder)
                .frame(width: 8, height: 8)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    MedicationsListView()
        .environmentObject(SettingsViewModel())
}
