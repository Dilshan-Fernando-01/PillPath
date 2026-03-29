//
//  TimeOfDayGroupSection.swift
//  PillPath — Home Module
//
//  Full Morning / Noon / Evening / Night section.
//  Designed for elderly users: large header, time range, current-period highlight.
//

import SwiftUI

struct TimeOfDayGroupSection: View {

    let group: TimeOfDayGroup
    var onMarkTaken: (DoseDisplayItem) -> Void = { _ in }
    var onUndoTaken: (DoseDisplayItem) -> Void = { _ in }

    private var isCurrentPeriod: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return DoseTimeLabel.from(hour: hour) == group.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            // Section header — larger for elderly readability
            sectionHeader

            // Missed warning banner
            if group.hasMissed {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.semanticError)
                        .font(.system(size: 14))
                    Text("\(group.label.displayName) medication missed — please check with your doctor")
                        .font(AppFont.body())
                        .fontWeight(.medium)
                        .foregroundStyle(Color.semanticError)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 10)
                .background(Color.semanticError.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }

            // Meal timing cards — skip empty sub-groups (no gap/placeholder text)
            VStack(spacing: 1) {
                ForEach(group.mealGroups.filter { !$0.isEmpty }) { mealGroup in
                    MealTimingSection(group: mealGroup, onMarkTaken: onMarkTaken, onUndoTaken: onUndoTaken)
                }
            }
            .background(isCurrentPeriod ? Color.brandPrimaryLight.opacity(0.3) : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isCurrentPeriod ? Color.brandPrimary.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Section header

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.sm) {
            // Icon — larger for elderly
            Image(systemName: group.label.systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(headerColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                // Period name — larger text
                Text(group.label.elderlyDisplayName)
                    .font(AppFont.headline())
                    .fontWeight(.bold)
                    .foregroundStyle(headerColor)

                // Time range hint
                if !group.label.timeRange.isEmpty {
                    Text(group.label.timeRange)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            // NOW badge or All-done badge
            if isCurrentPeriod && !group.allTaken && !group.isEmpty {
                Text("NOW")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            } else if group.allTaken {
                Label("All done", systemImage: "checkmark.circle.fill")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.semanticSuccess)
            } else if group.hasMissed {
                Label("\(group.allItems.filter { $0.effectiveStatus == .missed }.count) missed",
                      systemImage: "exclamationmark.circle.fill")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.semanticError)
            }
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    private var headerColor: Color {
        if group.hasMissed  { return Color.semanticError }
        if isCurrentPeriod  { return Color.brandPrimary }
        return Color.textSecondary
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
