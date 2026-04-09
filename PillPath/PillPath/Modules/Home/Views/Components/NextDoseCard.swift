//
//  NextDoseCard.swift
//  PillPath — Home Module
//


import SwiftUI

struct NextDoseCard: View {

    let item: DoseDisplayItem
    var onMarkTaken: () -> Void = {}

    @State private var showWrongPeriodAlert = false

    private var currentTimeLabel: DoseTimeLabel {
        DoseTimeLabel.from(hour: Calendar.current.component(.hour, from: .now))
    }

    private var isCorrectTimePeriod: Bool {
        currentTimeLabel == item.timeLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {

     
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

            
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 56, height: 56)
                    Image(systemName: "pills.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.brandPrimary)
                }

          
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

        
                Button(action: {
                    if isCorrectTimePeriod {
                        onMarkTaken()
                    } else {
                        showWrongPeriodAlert = true
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: isCorrectTimePeriod ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                            .font(.system(size: 28))
                        Text(isCorrectTimePeriod ? "Take Now" : item.timeLabel.displayName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(isCorrectTimePeriod ? .white : Color.brandPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCorrectTimePeriod ? Color.brandPrimary : Color.brandPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
                .alert("Scheduled for \(item.timeLabel.displayName)", isPresented: $showWrongPeriodAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("\(item.medicationName) is scheduled for \(item.timeLabel.displayName). You can take it when that time period begins.")
                }
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
