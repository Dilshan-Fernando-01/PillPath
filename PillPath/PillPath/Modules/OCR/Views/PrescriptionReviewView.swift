//
//  PrescriptionReviewView.swift
//  PillPath — OCR Module
//
//  Step 3: Review extracted medications.
//  Accept / Edit / Reject per item. "+ Add Another Manually". Save All.
//  Matches Figma "Medications Found" screen.
//

import SwiftUI

struct PrescriptionReviewView: View {

    @ObservedObject var viewModel: PrescriptionScanViewModel
    @State private var manualName = ""
    @State private var showManualField = false

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Medications Found")
                    .font(AppFont.title())
                    .foregroundStyle(Color.textPrimary)
                Text("We've identified the following medications from your scan. Please verify the details below.")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)

            ScrollView {
                VStack(spacing: AppSpacing.sm) {

                    // Item cards
                    ForEach($viewModel.scannedItems) { $item in
                        if !item.isRejected {
                            MedicationReviewCard(item: $item) {
                                viewModel.reject(item)
                            } onAccept: {
                                viewModel.accept(item)
                            } onEdit: {
                                viewModel.editingItem = item
                            } onAdvanced: {
                                viewModel.openAdvancedEdit(for: item)
                            }
                        }
                    }

                    // Manual add
                    if showManualField {
                        manualEntryField
                    }

                    // + Add Another Manually button
                    if !showManualField {
                        Button {
                            showManualField = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16))
                                Text("Add Another Manually")
                                    .font(AppFont.subheadline())
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(Color.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(
                                        Color.brandPrimary,
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
        // Quick edit sheet
        .sheet(item: $viewModel.editingItem) { item in
            QuickEditSheet(
                item: item,
                onSave: { name, amount, unit in
                    viewModel.updateItemName(item, newName: name)
                    viewModel.updateItemDosage(item, amount: amount, unit: unit)
                    viewModel.accept(item)
                },
                onAdvanced: {
                    viewModel.openAdvancedEdit(for: item)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Manual entry

    private var manualEntryField: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Medication name", text: $manualName)
                .font(AppFont.body())
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.brandPrimary, lineWidth: 1)
                )

            Button {
                viewModel.addManual(name: manualName)
                manualName = ""
                showManualField = false
            } label: {
                Text("Add")
                    .font(AppFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }

            Button {
                manualName = ""
                showManualField = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.textSecondary)
                    .font(.system(size: 20))
            }
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.acceptedCount == 0 {
                Text("Accept at least one medication to save.")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }

            PrimaryButton(
                title: viewModel.isImporting
                    ? "Saving…"
                    : "Save All Medications (\(viewModel.acceptedCount))",
                isLoading: viewModel.isImporting,
                isDisabled: viewModel.acceptedCount == 0
            ) {
                viewModel.importAll()
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .background(
            LinearGradient(colors: [Color.appBackground.opacity(0), Color.appBackground],
                           startPoint: .top, endPoint: .bottom)
            .frame(height: 20)
            .allowsHitTesting(false),
            alignment: .top
        )
        .background(Color.appBackground)
    }
}
