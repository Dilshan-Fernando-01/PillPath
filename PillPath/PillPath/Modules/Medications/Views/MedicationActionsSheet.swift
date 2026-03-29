//
//  MedicationActionsSheet.swift
//  PillPath — Medications Module
//
//  Bottom sheet shown when user taps a medication row.
//  Tapping Inactive/Active opens MedicationStatusChangeSheet for date + reason.
//

import SwiftUI

struct MedicationActionsSheet: View {

    let medication: Medication
    var onViewDetails: () -> Void = {}
    var onToggleActive: (MedicationStatusChange) -> Void = { _ in }
    var onDelete: () -> Void = {}
    var onDismiss: () -> Void = {}

    @State private var showDeleteConfirm = false
    @State private var showStatusSheet = false

    var body: some View {
        VStack(spacing: 0) {

            // Handle
            Capsule()
                .fill(Color.appBorder)
                .frame(width: 40, height: 4)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)

            // Header
            VStack(spacing: 4) {
                Text("Medication Actions")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                Text("\(medication.name) • \(medication.dosageDisplay)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.bottom, AppSpacing.lg)

            // Action rows
            VStack(spacing: 0) {
                actionRow(
                    icon: "pencil",
                    iconColor: Color.brandPrimary,
                    title: "View Details",
                    subtitle: "Change dosage or frequency",
                    action: { onViewDetails() }
                )
                Divider().padding(.leading, 72)

                actionRow(
                    icon: medication.isActive ? "pause.circle" : "checkmark.circle",
                    iconColor: medication.isActive ? Color.semanticWarning : Color.semanticSuccess,
                    title: medication.isActive ? "Mark as Inactive" : "Mark as Active",
                    subtitle: medication.isActive ? "Set a date and reason for stopping" : "Resume taking this medication",
                    action: { showStatusSheet = true }
                )
                Divider().padding(.leading, 72)

                actionRow(
                    icon: "trash",
                    iconColor: Color.semanticError,
                    title: "Delete Medication",
                    subtitle: "Permanently remove from history",
                    titleColor: Color.semanticError,
                    subtitleColor: Color.semanticError.opacity(0.7),
                    iconBg: Color.semanticError.opacity(0.1),
                    action: { showDeleteConfirm = true }
                )
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .padding(.horizontal, AppSpacing.md)

            // Cancel
            Button {
                onDismiss()
            } label: {
                Text("Cancel")
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(Color.appBackground)
        .confirmationDialog(
            "Delete \(medication.name)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete(); onDismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(medication.name) and all its history.")
        }
        .sheet(isPresented: $showStatusSheet) {
            MedicationStatusChangeSheet(
                medication: medication,
                targetIsActive: !medication.isActive,
                onConfirm: { change in
                    showStatusSheet = false
                    onToggleActive(change)
                    onDismiss()
                },
                onDismiss: { showStatusSheet = false }
            )
        }
    }

    // MARK: - Action Row

    private func actionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        titleColor: Color = Color.textPrimary,
        subtitleColor: Color = Color.textSecondary,
        iconBg: Color = Color.brandPrimaryLight,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(iconBg)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 19))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(titleColor)
                    Text(subtitle)
                        .font(AppFont.caption())
                        .foregroundStyle(subtitleColor)
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}
