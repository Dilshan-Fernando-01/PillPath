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


            if group.timing != .none {
                HStack(spacing: 5) {
                    Image(systemName: group.timing.systemIcon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(group.timing.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.4)
                }
                .foregroundStyle(Color.brandPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.brandPrimaryLight)
                .clipShape(Capsule())
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }

            if group.isEmpty {
                Text("No medications scheduled for this time")
                    .font(.system(size: 12))
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
                            .padding(.leading, 66)
                            .opacity(0.5)
                    }
                }
            }
        }
    }
}
