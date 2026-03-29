//
//  MedicationStatusChangeSheet.swift
//  PillPath — Medications Module
//
//  Presented when user taps "Mark as Inactive" or "Mark as Active".
//  Lets them choose effective date (now or specific) and provide a reason.
//

import SwiftUI

struct MedicationStatusChangeSheet: View {

    let medication: Medication
    let targetIsActive: Bool           // false = stopping, true = resuming
    var onConfirm: (MedicationStatusChange) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @State private var useNow = true
    @State private var effectiveDate = Date()
    @State private var reason = ""
    @State private var reasonError: String?

    private var isDeactivating: Bool { !targetIsActive }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {

                    // Header
                    headerSection

                    // Date picker
                    dateSection

                    // Reason
                    reasonSection

                    if let err = reasonError {
                        Text(err)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.semanticError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.md)
                    }

                    // Confirm button
                    PrimaryButton(
                        title: isDeactivating ? "Stop Medication" : "Resume Medication"
                    ) {
                        confirm()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(isDeactivating ? "Stop Medication" : "Resume Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(isDeactivating ? Color.semanticError.opacity(0.1) : Color.semanticSuccess.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(systemName: isDeactivating ? "pause.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(isDeactivating ? Color.semanticError : Color.semanticSuccess)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(medication.name)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                Text(isDeactivating ? "This medication will be moved to Stopped." : "This medication will resume as active.")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("EFFECTIVE DATE")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 0) {
                // Now option
                Button {
                    withAnimation { useNow = true }
                } label: {
                    HStack {
                        Image(systemName: useNow ? "circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(useNow ? Color.brandPrimary : Color.appBorder)
                        Text("Now")
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .shortened))
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(AppSpacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, AppSpacing.md)

                // Specific date option
                Button {
                    withAnimation { useNow = false }
                } label: {
                    HStack {
                        Image(systemName: !useNow ? "circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(!useNow ? Color.brandPrimary : Color.appBorder)
                        Text("Specific date & time")
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                }
                .buttonStyle(.plain)

                if !useNow {
                    DatePicker(
                        "",
                        selection: $effectiveDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .tint(Color.brandPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 2) {
                Text("REASON")
                    .font(AppFont.label())
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.5)
                Text("*")
                    .font(AppFont.label())
                    .foregroundStyle(Color.semanticError)
            }
            .padding(.horizontal, AppSpacing.md)

            // Quick-pick reasons
            let suggestions = isDeactivating
                ? ["Side effects", "Course completed", "Doctor advised", "Out of stock", "Temporary hold"]
                : ["Restarting course", "Doctor approved", "Symptoms returned", "New prescription"]

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(suggestions, id: \.self) { s in
                        Button {
                            reason = s
                            reasonError = nil
                        } label: {
                            Text(s)
                                .font(AppFont.caption())
                                .fontWeight(reason == s ? .semibold : .regular)
                                .foregroundStyle(reason == s ? .white : Color.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(reason == s ? Color.brandPrimary : Color.appSurface)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(reason == s ? Color.clear : Color.appBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }

            // Free-text field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                TextField("Or type your own reason…", text: $reason, axis: .vertical)
                    .font(AppFont.body())
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3...6)
                    .onChange(of: reason) { _, _ in reasonError = nil }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(
                reasonError != nil ? Color.semanticError : Color.appBorder, lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Actions

    private func confirm() {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reasonError = "Please provide a reason."
            return
        }
        let date = useNow ? Date() : effectiveDate
        let change = MedicationStatusChange(
            isActive: targetIsActive,
            effectiveDate: date,
            reason: trimmed
        )
        onConfirm(change)
    }
}
