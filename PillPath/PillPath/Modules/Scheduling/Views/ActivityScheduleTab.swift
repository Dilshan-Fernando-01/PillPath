//
//  ActivityScheduleTab.swift
//  PillPath — Scheduling Module
//
//  Tab 1: Week calendar + daily dose list.
//  Day circles: green=allTaken, red=hasMissed, yellow=hasPending, gray=noData.
//  Filter chips: Today / This Week / This Month.
//

import SwiftUI

struct ActivityScheduleTab: View {

    @ObservedObject var viewModel: ActivityViewModel
    @State private var showAddFlow = false
    @State var showHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Week navigator + day circles
                weekCalendarSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                // Search bar only — history moved to Quick Actions panel
                searchBar
                    .padding(.horizontal, AppSpacing.md)

                // Filter chips
                filterChips
                    .padding(.horizontal, AppSpacing.md)

                // Dose list
                doseListSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 100)
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showAddFlow, onDismiss: { viewModel.loadScheduleData() }) {
            AddMedicationFlowView()
        }
        .sheet(isPresented: $showHistory) {
            DoseHistoryView(viewModel: viewModel)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            TextField("Search medications...", text: $viewModel.scheduleSearch)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
            if !viewModel.scheduleSearch.isEmpty {
                Button { viewModel.scheduleSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
    }

    // MARK: - Week Calendar

    private var weekCalendarSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Month label + navigation
            HStack {
                Button {
                    viewModel.changeWeek(by: -1)
                    viewModel.loadScheduleData()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text(monthYearLabel)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    viewModel.changeWeek(by: 1)
                    viewModel.loadScheduleData()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // Day columns
            HStack(spacing: 0) {
                ForEach(viewModel.weekDays, id: \.self) { day in
                    dayColumn(for: day)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private func dayColumn(for day: Date) -> some View {
        let calendar  = Calendar.current
        let isToday   = calendar.isDateInToday(day)
        let isSelected = calendar.isDate(day, inSameDayAs: viewModel.selectedDate)
        let status    = viewModel.dayStatuses[day] ?? .noData

        return Button {
            viewModel.selectDate(day)
        } label: {
            VStack(spacing: 6) {
                Text(dayLetter(day))
                    .font(AppFont.caption())
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : dotColor(status))
                        .frame(width: 32, height: 32)

                    if isToday && !isSelected {
                        Circle()
                            .stroke(Color.brandPrimary, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }

                    Text(dayNumber(day))
                        .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : dotTextColor(status, isToday: isToday))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func dotColor(_ status: ActivityViewModel.DayStatus) -> Color {
        switch status {
        case .allTaken:  return Color.semanticSuccess.opacity(0.15)
        case .hasMissed: return Color.semanticError.opacity(0.15)
        case .hasPending: return Color.semanticWarning.opacity(0.15)
        case .noData:    return Color.appBorder.opacity(0.5)
        }
    }

    private func dotTextColor(_ status: ActivityViewModel.DayStatus, isToday: Bool) -> Color {
        if isToday { return Color.brandPrimary }
        switch status {
        case .allTaken:  return Color.semanticSuccess
        case .hasMissed: return Color.semanticError
        case .hasPending: return Color.semanticWarning
        case .noData:    return Color.textSecondary
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ActivityViewModel.ScheduleFilter.allCases, id: \.self) { filter in
                Button {
                    viewModel.scheduleFilter = filter
                    applyFilter(filter)
                } label: {
                    Text(filter.displayName)
                        .font(AppFont.caption())
                        .fontWeight(viewModel.scheduleFilter == filter ? .semibold : .regular)
                        .foregroundStyle(viewModel.scheduleFilter == filter ? .white : Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs + 2)
                        .background(viewModel.scheduleFilter == filter ? Color.brandPrimary : Color.appSurface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                viewModel.scheduleFilter == filter ? Color.clear : Color.appBorder,
                                lineWidth: 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Dose List

    private var doseListSection: some View {
        VStack(spacing: AppSpacing.sm) {
            let doses = filteredDoses

            if doses.isEmpty {
                emptyDoseState
            } else {
                ForEach(doses) { item in
                    ScheduleDoseRow(item: item)
                }
            }
        }
    }

    private var filteredDoses: [DoseDisplayItem] {
        let calendar = Calendar.current
        let doses = viewModel.filteredSelectedDayDoses
        switch viewModel.scheduleFilter {
        case .today:
            return doses.filter {
                calendar.isDate($0.scheduledAt, inSameDayAs: viewModel.selectedDate)
            }
        case .thisWeek, .thisMonth:
            return doses
        }
    }

    private var emptyDoseState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text("No doses scheduled")
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
            Button {
                showAddFlow = true
            } label: {
                Text("Add Medication")
                    .font(AppFont.subheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Helpers

    private var monthYearLabel: String {
        let days = viewModel.weekDays
        guard let first = days.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: first)
    }

    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func applyFilter(_ filter: ActivityViewModel.ScheduleFilter) {
        let calendar = Calendar.current
        switch filter {
        case .today:
            viewModel.selectDate(calendar.startOfDay(for: .now))
        case .thisWeek, .thisMonth:
            viewModel.loadDosesForSelectedDate()
        }
    }
}

// MARK: - Schedule Dose Row

struct ScheduleDoseRow: View {

    let item: DoseDisplayItem

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeDisplay)
                    .font(AppFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text(item.timeLabel.displayName)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(width: 56, alignment: .trailing)

            // Timeline dot
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.medicationName)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text(item.dosageDisplay)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Status badge
            Text(item.effectiveStatus.displayName)
                .font(AppFont.caption())
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: item.scheduledAt)
    }

    private var statusColor: Color {
        switch item.effectiveStatus {
        case .taken:   return Color.semanticSuccess
        case .missed:  return Color.semanticError
        case .pending: return Color.semanticWarning
        case .skipped: return Color.textSecondary
        }
    }
}
