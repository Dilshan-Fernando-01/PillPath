//
//  StepProgressView.swift
//  PillPath — Design System
//
//  "STEP X OF 8   |   37% Complete" header + progress bar.
//  Matches the Add Medication stepper shown in Figma.
//

import SwiftUI

struct StepProgressView: View {

    let currentStep: Int
    let totalSteps: Int

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps)
    }

    private var percentText: String {
        "\(Int(progress * 100))% Complete"
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("STEP \(currentStep) OF \(totalSteps)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.5)

                Spacer()

                Text(percentText)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.brandPrimary)
                    .fontWeight(.semibold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBorder)
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.brandPrimary)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        StepProgressView(currentStep: 1, totalSteps: 8)
        StepProgressView(currentStep: 3, totalSteps: 8)
        StepProgressView(currentStep: 7, totalSteps: 8)
    }
    .padding()
    .background(Color.appBackground)
}
