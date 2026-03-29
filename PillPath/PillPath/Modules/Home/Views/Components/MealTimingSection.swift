//
//  MealTimingSection.swift
//  PillPath — Home Module
//
//  Card containing all doses for one meal-timing slot (BEFORE MEAL / WITH MEAL / AFTER MEAL).
//  Shows "No medications scheduled" when empty.
//

import SwiftUI

struct MealTimingSection: View {

    let group: MealTimingGroup
    var onMarkTaken: (DoseDisplayItem) -> Void = { _ in }
    var onUndoTaken: (DoseDisplayItem) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Meal timing label
            if group.timing != .none {
                Text(group.timing.displayName.uppercased())
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
                    .kerning(0.5)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }

            if group.isEmpty {
                Text("No medications scheduled for this time")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
            } else {
                ForEach(group.items) { item in
                    DoseItemRow(
                        item: item,
                        onMarkTaken: { onMarkTaken(item) },
                        onUndoTaken: { onUndoTaken(item) }
                    )

                    if item.id != group.items.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }
}
