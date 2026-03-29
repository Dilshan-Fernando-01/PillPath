//
//  AddMedicationFlowView.swift
//  PillPath — Medications Module
//
//  Root container for the 8-step Add Medication wizard.
//  Hosts the step router and the shared sticky footer.
//

import SwiftUI

struct AddMedicationFlowView: View {

    @StateObject private var viewModel: AddMedicationViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @MainActor
    init(viewModel: AddMedicationViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AddMedicationViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // ── Step content ──────────────────────────────────
                VStack(spacing: 0) {
                    StepProgressView(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // ── Sticky footer ─────────────────────────────────
                footerButtons
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.lg)
                    .background(
                        LinearGradient(
                            colors: [Color.appBackground.opacity(0), Color.appBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false),
                        alignment: .top
                    )
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.currentStep == 1 { dismiss() }
                        else { viewModel.previousStep() }
                    } label: {
                        Image(systemName: viewModel.currentStep == 1 ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
            // Success redirect
            .fullScreenCover(isPresented: $viewModel.didSave) {
                if let med = viewModel.savedMedication {
                    MedicationSavedSuccessView(
                        medication: med,
                        reviewItems: viewModel.reviewItems,
                        onDone: { dismiss() },
                        onAddAnother: {
                            viewModel.didSave = false
                            viewModel.currentStep = 1
                        }
                    )
                }
            }
        }
    }

    // MARK: - Step Router

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                switch viewModel.currentStep {
                case 1: AddMedStep1NameView(viewModel: viewModel)
                case 2: AddMedStep2TypeView(viewModel: viewModel)
                case 3: AddMedStep3DosageView(viewModel: viewModel)
                case 4: AddMedStep4ScheduleView(viewModel: viewModel)
                case 5: AddMedStep5TimeView(viewModel: viewModel)
                case 6: AddMedStep6MealView(viewModel: viewModel)
                case 7: AddMedStep7AdvancedView(viewModel: viewModel)
                case 8: AddMedStep8ReviewView(viewModel: viewModel)
                default: EmptyView()
                }
                // Bottom padding for footer
                Spacer().frame(height: 90)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.lg)
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            if let error = viewModel.saveError {
                Text(error)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.semanticError)
                    .multilineTextAlignment(.center)
            }

            if viewModel.currentStep == viewModel.totalSteps {
                PrimaryButton(
                    title: viewModel.isSaving ? "Saving…" : "Save Medication",
                    isLoading: viewModel.isSaving
                ) {
                    Task { await viewModel.save() }
                }
            } else {
                PrimaryButton(
                    title: "Continue",
                    isDisabled: !viewModel.canProceed
                ) {
                    viewModel.nextStep()
                }
            }
        }
    }

    // MARK: - Step Titles

    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "Medication Name"
        case 2: return "Medication Type"
        case 3: return "Dosage"
        case 4: return "Schedule"
        case 5: return "Time of Day"
        case 6: return "Meal Timing"
        case 7: return "Advanced Options"
        case 8: return "Review & Save"
        default: return "Add Medication"
        }
    }
}

#Preview {
    AddMedicationFlowView()
        .environmentObject(SettingsViewModel())
}
