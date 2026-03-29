//
//  TimeOfDayCard.swift
//  PillPath — Design System
//
//  Selectable time-of-day card used in Step 5 (when do you take it?).
//  Matches Figma: icon, title, time range. Blue fill when selected.
//

import SwiftUI

struct TimeOfDayCard: View {

    let timeLabel: DoseTimeLabel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 52, height: 52)
                    Image(systemName: timeLabel.systemIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                }
                Text(timeLabel.displayName)
                    .font(AppFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textPrimary)

                Text(timeLabel.timeRange)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Usage

struct TimeOfDayGrid: View {
    @Binding var selected: Set<DoseTimeLabel>

    private let items: [DoseTimeLabel] = [.morning, .noon, .evening, .night]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
            ForEach(items) { label in
                TimeOfDayCard(timeLabel: label, isSelected: selected.contains(label)) {
                    if selected.contains(label) { selected.remove(label) }
                    else { selected.insert(label) }
                }
            }
        }
    }
}

#Preview {
    @State var selected: Set<DoseTimeLabel> = [.morning, .night]
    return TimeOfDayGrid(selected: $selected)
        .padding()
        .background(Color.appBackground)
}
