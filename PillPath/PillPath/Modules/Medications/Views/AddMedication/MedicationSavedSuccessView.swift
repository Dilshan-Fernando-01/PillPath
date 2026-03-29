//
//  MedicationSavedSuccessView.swift
//  PillPath — Medications Module
//
//  Shown after a medication is saved. Offers the user a chance to sync
//  the medication's schedule to their iOS Calendar via EventKit.
//

import SwiftUI
import EventKit

struct MedicationSavedSuccessView: View {

    let medication: Medication
    let reviewItems: [ReviewItem]
    var onDone: () -> Void = {}
    var onAddAnother: () -> Void = {}

    @StateObject private var eventKit = EventKitService.shared
    @State private var calendarSyncState: SyncState = .idle
    @State private var showPermissionAlert = false

    private enum SyncState {
        case idle, syncing, synced, denied
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    // Success illustration
                    successHeader

                    // Review items
                    reviewCard

                    // Calendar sync card
                    calendarSyncCard

                    // Actions
                    VStack(spacing: AppSpacing.md) {
                        PrimaryButton(title: "Done") { onDone() }

                        Button("Add Another Medication") { onAddAnother() }
                            .font(AppFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandPrimary)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    Spacer().frame(height: 40)
                }
                .padding(.top, AppSpacing.xl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .alert("Calendar Access Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow PillPath to access your Calendar in Settings to sync medication reminders.")
        }
    }

    // MARK: - Sub-views

    private var successHeader: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.semanticSuccess.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.semanticSuccess)
            }

            Text("Medication Added!")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text("\(medication.name) has been saved to your medication list.")
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("SUMMARY")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 0) {
                ForEach(reviewItems) { item in
                    HStack {
                        Text(item.label)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Text(item.value)
                            .font(AppFont.body())
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)

                    if item.id != reviewItems.last?.id {
                        Divider().padding(.leading, AppSpacing.md)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var calendarSyncCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("CALENDAR")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.brandPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to iOS Calendar")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text("Creates recurring reminders in your Calendar app")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                calendarSyncButton
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .padding(.horizontal, AppSpacing.md)
        }
    }

    @ViewBuilder
    private var calendarSyncButton: some View {
        switch calendarSyncState {
        case .idle:
            Button {
                syncToCalendar()
            } label: {
                Text("Add")
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .syncing:
            ProgressView()
                .tint(Color.brandPrimary)

        case .synced:
            Label("Added", systemImage: "checkmark.circle.fill")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.semanticSuccess)

        case .denied:
            Button {
                showPermissionAlert = true
            } label: {
                Text("Allow Access")
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.semanticWarning)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func syncToCalendar() {
        calendarSyncState = .syncing
        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .fullAccess || status == .writeOnly {
            performSync()
        } else if status == .notDetermined {
            eventKit.requestAccess { granted in
                if granted {
                    performSync()
                } else {
                    calendarSyncState = .denied
                }
            }
        } else {
            calendarSyncState = .denied
            showPermissionAlert = true
        }
    }

    private func performSync() {
        eventKit.createPillPathCalendarIfNeeded()
        // Use the medication's start date at 9 AM as the first dose reminder
        let morning = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now

        let count = eventKit.syncMedicationToCalendar(
            medicationName: medication.name,
            dosageDisplay: medication.dosageDisplay,
            doseTimes: [morning],
            notes: medication.notes
        )
        calendarSyncState = count > 0 ? .synced : .idle
    }
}
