//
//  MedicationReviewCard.swift
//  PillPath — OCR Module
//
//  Single scanned medication card on the review screen.
//  Shows: accepted indicator + name + confidence badge + Edit button.
//  Matches Figma "Medications Found" card style.
//

import SwiftUI

struct MedicationReviewCard: View {

    @Binding var item: ScannedMedicationItem
    var onReject: () -> Void   = {}
    var onAccept: () -> Void   = {}
    var onEdit: () -> Void     = {}
    var onAdvanced: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSpacing.md) {

            // Accept / pending toggle
            Button {
                if item.isAccepted { item.action = .pending }
                else { onAccept() }
            } label: {
                Image(systemName: item.isAccepted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(item.isAccepted ? Color.semanticSuccess : Color.appBorder)
            }
            .buttonStyle(.plain)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.sm) {
                    Text(item.displayName)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    confidenceBadge
                }

                Text("\(item.suggestedDosageAmount.formatted()) \(item.suggestedDosageUnit.displayName)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)

                if item.originalName.lowercased() != item.displayName.lowercased() {
                    Text("Scanned: \"\(item.originalName)\"")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Text("Edit")
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimaryLight)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(
                    item.isAccepted ? Color.semanticSuccess.opacity(0.4) : Color.appBorder,
                    lineWidth: item.isAccepted ? 1.5 : 1
                )
        )
        .appCardShadow()
    }

    // MARK: - Confidence badge

    @ViewBuilder
    private var confidenceBadge: some View {
        switch item.matchStatus {
        case .exact:
            badge(label: "HIGH CONFIDENCE", color: Color.semanticSuccess)
        case .partial:
            badge(label: "REVIEW", color: Color.semanticWarning)
        case .none:
            badge(label: "NO MATCH", color: Color.semanticError)
        }
    }

    private func badge(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }
}
