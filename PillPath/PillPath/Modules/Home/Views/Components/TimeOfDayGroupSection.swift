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
    
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(headerColor.opacity(isCurrentPeriod ? 0.15 : 0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: group.label.systemIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(headerColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(group.label.elderlyDisplayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(headerColor)
                if !group.label.timeRange.isEmpty {
                    Text(group.label.timeRange)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

          
            if isCurrentPeriod && !group.allTaken && !group.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Text("NOW")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.brandPrimary)
                .clipShape(Capsule())
            } else if group.allTaken {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("All done")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.semanticSuccess)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.semanticSuccess.opacity(0.1))
                .clipShape(Capsule())
            } else if group.hasMissed {
                let count = group.allItems.filter { $0.effectiveStatus == .missed }.count
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text("\(count) missed")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.semanticError)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.semanticError.opacity(0.1))
                .clipShape(Capsule())
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
