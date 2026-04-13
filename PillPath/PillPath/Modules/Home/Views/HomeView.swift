//
//  HomeView.swift
//  PillPath — Home Module
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

              
                topBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)

               
                dateHeading
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)

                CalendarStripView(selectedDate: $viewModel.selectedDate) { date in
                    viewModel.selectDate(date)
                }
                .padding(.bottom, AppSpacing.lg)


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


    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "sun.max.fill"
        case 12..<17: return "sun.haze.fill"
        case 17..<21: return "moon.stars.fill"
        default:      return "moon.zzz.fill"
        }
    }

    private var todayProgress: (taken: Int, total: Int) {
        let all = viewModel.timeOfDayGroups.flatMap(\.allItems)
        let taken = all.filter { $0.effectiveStatus == .taken }.count
        return (taken, all.count)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: greetingIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(greeting)
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.textSecondary)
                }
                Text("Today's Meds")
                    .font(AppFont.largeTitle())
                    .foregroundStyle(Color.textPrimary)

                if todayProgress.total > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 11))
                        Text("\(todayProgress.taken) of \(todayProgress.total) taken")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(todayProgress.taken == todayProgress.total ? Color.semanticSuccess : Color.brandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (todayProgress.taken == todayProgress.total ? Color.semanticSuccess : Color.brandPrimary)
                            .opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }

            Spacer()

 
            if let contact = settings.emergencyContact {
                emergencyCallButton(contact: contact)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimaryLight)
                        .frame(width: 42, height: 42)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

 

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
