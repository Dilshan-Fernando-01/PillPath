//
//  RadioListItem.swift
//  PillPath — Design System
//
//  Full-width row with icon, label, and radio button.
//  Used in Step 4 (schedule type: Daily, Every X hours, etc.)
//

import SwiftUI

struct RadioListItem: View {

    let icon: String
    let title: String
    var subtitle: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimaryLight : Color(hex: "#F5F6FA"))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.body())
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(Color.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 12, height: 12)
                    }
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

// MARK: - Schedule Frequency List

struct ScheduleFrequencyList: View {
    @Binding var selected: ScheduleFrequency

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(ScheduleFrequency.allCases) { freq in
                RadioListItem(
                    icon: freq.systemIcon,
                    title: freq.displayName,
                    isSelected: selected == freq
                ) { selected = freq }
            }
        }
    }
}

#Preview {
    @State var freq: ScheduleFrequency = .daily
    return ScheduleFrequencyList(selected: $freq)
        .padding()
        .background(Color.appBackground)
}
