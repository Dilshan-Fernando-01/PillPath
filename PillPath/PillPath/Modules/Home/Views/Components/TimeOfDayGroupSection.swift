//
//  TimeOfDayGroupSection.swift
//  PillPath — Home Module
//
//  Full Morning / Noon / Evening / Night section.
//  Shows missed warning banner when that time slot has unacknowledged missed doses.
//

import SwiftUI

struct TimeOfDayGroupSection: View {

    let group: TimeOfDayGroup
    var onMarkTaken: (DoseDisplayItem) -> Void = { _ in }
    var onUndoTaken: (DoseDisplayItem) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            // Section header (MORNING / NOON / EVENING / NIGHT)
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: group.label.systemIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(headerColor)

                Text(group.label.displayName.uppercased())
                    .font(AppFont.caption())
                    .fontWeight(.bold)
                    .foregroundStyle(headerColor)
                    .kerning(0.8)

                Spacer()

                if group.allTaken {
                    Label("All done", systemImage: "checkmark.circle.fill")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticSuccess)
                }
            }
            .padding(.horizontal, AppSpacing.xs)

            // Missed warning banner
            if group.hasMissed {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.semanticError)
                        .font(.system(size: 13))
                    Text("\(group.label.displayName) medication missed")
                        .font(AppFont.caption())
                        .fontWeight(.medium)
                        .foregroundStyle(Color.semanticError)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 8)
                .background(Color.semanticError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }

            // Meal timing cards
            VStack(spacing: 1) {
                ForEach(group.mealGroups) { mealGroup in
                    MealTimingSection(group: mealGroup, onMarkTaken: onMarkTaken, onUndoTaken: onUndoTaken)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }

    private var headerColor: Color {
        group.hasMissed ? Color.semanticError : Color.textSecondary
    }
}

#Preview {
    let items = [DoseDisplayItem.preview(status: .pending), DoseDisplayItem.preview(status: .missed)]
    let mealGroup = MealTimingGroup(id: .before, timing: .before, items: items)
    let group = TimeOfDayGroup(id: .morning, label: .morning, mealGroups: [mealGroup])
    return TimeOfDayGroupSection(group: group)
        .padding()
        .background(Color.appBackground)
}
