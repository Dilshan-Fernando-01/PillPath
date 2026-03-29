//
//  AddMedStep1NameView.swift
//  PillPath — Medications Module
//
//  Step 1: Enter medication name + optional FDA auto-complete.
//

import SwiftUI

struct AddMedStep1NameView: View {

    @ObservedObject var viewModel: AddMedicationViewModel
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            // Header
            stepHeader(
                title: "What is the medication called?",
                subtitle: "Enter the name as written on the label or prescription."
            )

            // Name field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Medication Name")
                    .font(AppFont.subheadline())
                    .foregroundStyle(Color.textSecondary)

                HStack {
                    Image(systemName: "pills")
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 24)
                    TextField("e.g. Paracetamol, Aspirin", text: $viewModel.medicationName)
                        .font(AppFont.body())
                        .focused($nameFocused)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.medicationName) { _, newValue in
                            viewModel.searchFDA(query: newValue)
                        }
                    if !viewModel.medicationName.isEmpty {
                        Button {
                            viewModel.medicationName = ""
                            viewModel.fdaSearchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(nameFocused ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
                )
            }

            // FDA suggestions
            if !viewModel.fdaSearchResults.isEmpty {
                fdaSuggestions
            }

            Spacer()
        }
        .onAppear { nameFocused = true }
    }

    // MARK: - FDA Suggestion List

    private var fdaSuggestions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Suggestions from openFDA")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.fdaSearchResults.enumerated()), id: \.element.id) { index, result in
                    Button {
                        viewModel.applyFDAResult(result)
                        nameFocused = false
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.brandPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.brandName)
                                    .font(AppFont.subheadline())
                                    .foregroundStyle(Color.textPrimary)
                                if let generic = result.genericName {
                                    Text(generic)
                                        .font(AppFont.caption())
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.fdaSearchResults.count - 1 {
                        Divider().padding(.leading, AppSpacing.xl)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }
}
