//
//  HomeView.swift
//  PillPath — Home Module
//
//  Landing page. Matches Figma "Medication Home Screen".
//  No authentication — opens directly on launch.
//

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var settings: SettingsViewModel

    @State private var showFullSchedule = false
    @State private var showMarkAllConfirm = false

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Top bar ──────────────────────────────────────
                topBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)

                // ── Date heading ─────────────────────────────────
                dateHeading
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)

                // ── Calendar strip ───────────────────────────────
                CalendarStripView(selectedDate: $viewModel.selectedDate) { date in
                    viewModel.selectDate(date)
                }
                .padding(.bottom, AppSpacing.lg)

                // ── Body ─────────────────────────────────────────
                if viewModel.isLoading {
                    LoadingView(message: "Loading medications...")
                        .frame(height: 300)

                } else if viewModel.timeOfDayGroups.allSatisfy(\.isEmpty) {
                    emptyState

                } else {
                    VStack(spacing: AppSpacing.lg) {

                        // Next dose highlight
                        if let next = viewModel.nextDose {
                            NextDoseCard(item: next) {
                                viewModel.markTaken(next)
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // Today's schedule header
                        scheduleHeader
                            .padding(.horizontal, AppSpacing.md)

                        // Grouped dose sections
                        LazyVStack(spacing: AppSpacing.lg) {
                            ForEach(viewModel.timeOfDayGroups.filter { !$0.isEmpty }) { group in
                                TimeOfDayGroupSection(
                                    group: group,
                                    onMarkTaken: { viewModel.markTaken($0) },
                                    onUndoTaken: { viewModel.undoTaken($0) }
                                )
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)

                        // View full schedule link
                        Button {
                            showFullSchedule = true
                        } label: {
                            Text("View Full Schedule of the Day")
                                .font(AppFont.subheadline())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.brandPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                }

                // Bottom padding for the floating nav bar
                Spacer().frame(height: 100)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showFullSchedule) {
            FullScheduleSheet(
                groups: viewModel.timeOfDayGroups,
                onMarkTaken: { viewModel.markTaken($0) },
                isPresented: $showFullSchedule
            )
        }
        .confirmationDialog(
            "Mark all pending doses as taken?",
            isPresented: $showMarkAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark All Taken") { viewModel.markAllTaken() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { viewModel.loadDoses(for: viewModel.selectedDate) }
        .refreshable  { viewModel.loadDoses(for: viewModel.selectedDate) }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Date label
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(AppFont.subheadline())
                    .foregroundStyle(Color.textSecondary)
                Text("Today's Meds")
                    .font(AppFont.largeTitle())
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            // Emergency contact button (only if set)
            if let contact = settings.emergencyContact {
                emergencyCallButton(contact: contact)
            } else {
                // Profile placeholder
                Circle()
                    .stroke(Color.appBorder, lineWidth: 1.5)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textSecondary)
                    )
            }
        }
    }

    // MARK: - Emergency Call Button

    private func emergencyCallButton(contact: EmergencyContact) -> some View {
        Button {
            guard let url = contact.callURL else { return }
            UIApplication.shared.open(url)
        } label: {
            ZStack {
                Circle()
                    .fill(Color.semanticError.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "phone.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.semanticError)
            }
        }
        .accessibilityLabel("Call \(contact.name)")
    }

    // MARK: - Date Heading

    private var dateHeading: some View {
        Group {
            // Only show if not today — "Today" is already in the title
            if !calendar.isDateInToday(viewModel.selectedDate) {
                Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Schedule Header

    private var scheduleHeader: some View {
        HStack {
            Text("Today's Schedule")
                .font(AppFont.headline())
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button("Mark All Taken") {
                showMarkAllConfirm = true
            }
            .font(AppFont.caption())
            .fontWeight(.semibold)
            .foregroundStyle(Color.brandPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 6)
            .background(Color.brandPrimaryLight)
            .clipShape(Capsule())
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "pills",
            title: "No Medications",
            subtitle: "No medications scheduled for this day. Add medications from the Meds tab.",
            actionLabel: nil
        )
        .frame(height: 300)
    }
}

#Preview {
    HomeView()
        .environmentObject(SettingsViewModel())
}
