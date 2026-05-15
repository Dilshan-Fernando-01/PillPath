
import SwiftUI
import UIKit

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
                    
                    searchBar
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)

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
                    let schedule = viewModel.schedule(for: captured.id)
                    selectedMedication = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editViewModel = AddMedicationViewModel.editing(medication: captured, schedule: schedule)
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
                onRestock: { amount in
                    viewModel.restockMedication(med, amount: amount)
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



    private var filteredMedications: [Medication] {
        guard !searchText.isEmpty else { return viewModel.medications }
        return viewModel.medications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.genericName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }


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


struct MedicationRowCard: View {

    let medication: Medication
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSpacing.md) {

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 48, height: 48)
                if let img = PhotoStorage.load(medication.photoURL) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Image(systemName: medication.form.systemIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.brandPrimary)
                }
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
                    if medication.currentQuantity > 0 {
                        Text("•")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                        Text("\(medication.stockTrackingSummary) remaining")
                            .font(AppFont.caption())
                            .foregroundStyle(medication.lowQuantityAlert && medication.currentQuantity <= medication.lowQuantityThreshold
                                ? Color.semanticError : Color.textSecondary)
                    }
                }

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
