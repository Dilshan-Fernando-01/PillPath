//
//  SuccessView.swift
//  PillPath — Design System
//
//  Generic success screen.
//  Matches Figma "Scan Prescription: Step 5 — X Medications Saved!"
//

import SwiftUI

struct SuccessView: View {

    let title: String
    let subtitle: String
    var items: [SuccessItem] = []
    var primaryActionLabel: String = "Go to Home"
    var secondaryActionLabel: String?
    var onPrimary: () -> Void = {}
    var onSecondary: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Spacer(minLength: AppSpacing.xl)

                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.semanticSuccess.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.semanticSuccess)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(AppFont.largeTitle())
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(AppFont.body())
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Saved items list
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SAVED ITEMS")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                            .kerning(0.5)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.bottom, AppSpacing.sm)

                        VStack(spacing: 0) {
                            ForEach(items) { item in
                                HStack(spacing: AppSpacing.md) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandPrimaryLight)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "cross.case.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.brandPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(AppFont.body())
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.textPrimary)
                                        Text(item.subtitle)
                                            .font(AppFont.caption())
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                if item.id != items.last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .appCardShadow()
                    }
                }

                Spacer()

                // Actions
                VStack(spacing: AppSpacing.sm) {
                    PrimaryButton(title: primaryActionLabel, action: onPrimary)

                    if let secLabel = secondaryActionLabel {
                        SecondaryButton(title: secLabel, action: onSecondary ?? {})
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

struct SuccessItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String

    init(id: UUID = .init(), title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

#Preview {
    SuccessView(
        title: "2 Medications Saved!",
        subtitle: "Your schedule has been updated.",
        items: [
            SuccessItem(title: "Lisinopril",  subtitle: "10mg • Once daily"),
            SuccessItem(title: "Metformin",   subtitle: "500mg • Twice daily")
        ],
        primaryActionLabel: "Go to Home",
        secondaryActionLabel: "Scan Another"
    )
}
