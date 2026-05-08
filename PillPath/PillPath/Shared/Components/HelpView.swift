
import SwiftUI

struct HelpView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    helpSection(
                        icon: "pills.fill",
                        title: "Adding a Medication Manually",
                        steps: [
                            "Tap the + button on the Medications tab.",
                            "Enter the medication name. You can search our drug database or type a custom name.",
                            "Select the medication form (tablet, capsule, liquid, etc.).",
                            "Set the dosage amount and unit (pills, mg, mL).",
                            "Choose how often to take it — daily, every X hours, specific days, or custom dates.",
                            "Pick the time(s) of day and any meal timing preference.",
                            "Optionally add advanced details: start/end date, reminders, a photo, display name, notes, and current quantity.",
                            "Review the summary and tap Save."
                        ]
                    )

                    helpSection(
                        icon: "doc.text.viewfinder",
                        title: "Adding via Label Scan",
                        steps: [
                            "Tap the scan icon in the bottom navigation bar.",
                            "Point your camera at a medication label or prescription.",
                            "The app reads the text and pre-fills the medication name, form, and dosage.",
                            "Review the auto-filled details, make any corrections, then continue through the steps as normal."
                        ]
                    )

                    helpSection(
                        icon: "calendar.badge.plus",
                        title: "Adding Medical Events",
                        steps: [
                            "Go to the Activity tab and tap the Events section.",
                            "Tap + to create a new event.",
                            "Enter the event title, date, type (appointment, surgery, test, etc.), and any notes.",
                            "Events appear in your timeline and can be linked to medications added later."
                        ]
                    )

                    helpSection(
                        icon: "chart.bar.fill",
                        title: "Viewing Analytics",
                        steps: [
                            "Tap the + button in the footer and choose Analytics.",
                            "Use the month and year picker to view history for any period.",
                            "See your overall adherence percentage, streaks, and dose-by-dose history.",
                            "Tap a medication in the chart to filter by that specific medication."
                        ]
                    )

                    helpSection(
                        icon: "checkmark.circle.fill",
                        title: "Taking a Dose",
                        steps: [
                            "Open the Home tab — today's scheduled doses appear grouped by time of day.",
                            "Tap Take next to a dose when you take it.",
                            "The app logs the exact time and updates your remaining quantity automatically.",
                            "If your quantity drops below the alert threshold, you will receive a low-supply notification."
                        ]
                    )

                    helpSection(
                        icon: "gearshape.fill",
                        title: "Settings & Security",
                        steps: [
                            "Open Settings from the + quick actions panel.",
                            "Enable Face ID or Touch ID for quick login under the Security section.",
                            "Adjust notification preferences and app appearance (light/dark/system).",
                            "Tap Sign Out to log out of your account."
                        ]
                    )

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

    private func helpSection(icon: String, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.brandPrimary)
                }
                Text(title)
                    .font(AppFont.subheadline())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.brandPrimary)
                            .clipShape(Circle())
                        Text(step)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }
}

#Preview {
    HelpView()
        .environmentObject(SettingsViewModel())
}
