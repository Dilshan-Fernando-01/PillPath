//
//  MealTimingSelector.swift
//  PillPath — Design System
//
//  Step 6 component: segmented header + selectable detail rows.
//  "Before Meal / With Meal / After Meal" with description card.
//

import SwiftUI

struct MealTimingSelector: View {
    @Binding var selected: MealTiming

    private let options: [MealTiming] = [.before, .with, .after]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Segmented control
            HStack(spacing: 0) {
                ForEach(options) { timing in
                    Button(timing.shortName) {
                        withAnimation(.easeInOut(duration: 0.2)) { selected = timing }
                    }
                    .font(AppFont.subheadline())
                    .fontWeight(selected == timing ? .semibold : .regular)
                    .foregroundStyle(selected == timing ? Color.brandPrimary : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selected == timing ? Color.appSurface : Color.clear)
                    .clipShape(Capsule())
                }
            }
            .padding(4)
            .background(Color.appBackground)
            .clipShape(Capsule())

            // Detail rows
            VStack(spacing: AppSpacing.sm) {
                ForEach(options) { timing in
                    MealTimingRow(timing: timing, isSelected: selected == timing) {
                        selected = timing
                    }
                }
            }
        }
    }
}

struct MealTimingRow: View {
    let timing: MealTiming
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: timing.systemIcon)
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timing.shortName)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text(timing.description)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brandPrimary)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.textSecondary)
                        .font(.system(size: 14))
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @State var timing: MealTiming = .with
    return MealTimingSelector(selected: $timing)
        .padding()
        .background(Color.appBackground)
}
