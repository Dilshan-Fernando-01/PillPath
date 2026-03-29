//
//  NextDoseCard.swift
//  PillPath — Home Module
//
//  "Next Dose" highlight card shown near the top of the home screen.
//  Matches Figma pill icon + name + time remaining chip.
//

import SwiftUI

struct NextDoseCard: View {

    let item: DoseDisplayItem
    var onMarkTaken: () -> Void = {}

    var body: some View {
        HStack(spacing: AppSpacing.md) {

            // Icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 48, height: 48)
                Image(systemName: "pills.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.brandPrimary)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text("Next Dose")
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.3)

                Text(item.medicationName)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)

                Text("\(item.dosageDisplay) • \(item.scheduledAt.formatted(.dateTime.hour().minute()))")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Time chip + take button
            VStack(spacing: AppSpacing.xs) {
                Text(item.timeRemainingDisplay)
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())

                Button("Take", action: onMarkTaken)
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1)
        )
        .appCardShadow()
    }
}

#Preview {
    NextDoseCard(item: .preview(status: .pending))
        .padding()
        .background(Color.appBackground)
}
