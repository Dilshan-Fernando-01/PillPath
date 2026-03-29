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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

            // Header label
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                Text("NEXT DOSE")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .kerning(0.5)
                Spacer()
                Text(item.timeRemainingDisplay)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 6)
            .background(Color.brandPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            HStack(spacing: AppSpacing.md) {

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 56, height: 56)
                    Image(systemName: "pills.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.brandPrimary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.medicationName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                        Text(item.scheduledAt.formatted(.dateTime.hour().minute()))
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        Text("·")
                            .foregroundStyle(Color.textSecondary)
                        Text(item.dosageDisplay)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                // Large "Take Now" button for elderly
                Button(action: onMarkTaken) {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                        Text("Take Now")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1.5)
        )
        .appCardShadow()
    }
}

#Preview {
    NextDoseCard(item: .preview(status: .pending))
        .padding()
        .background(Color.appBackground)
}
