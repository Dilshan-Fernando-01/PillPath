//
//  ActivityEventsTab.swift
//  PillPath — Scheduling Module
//
//  Tab 3: Medical events grouped by month.
//  Tap to view detail. "Add New Event" button.
//

import SwiftUI

struct ActivityEventsTab: View {

    @ObservedObject var viewModel: ActivityViewModel
    @State private var selectedEvent: MedicalEvent?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                // Search bar
                searchBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)

                if viewModel.allEvents.isEmpty {
                    emptyState
                        .padding(.top, AppSpacing.xl)
                } else if viewModel.filteredEventsByMonth.isEmpty {
                    noResultsState
                        .padding(.top, AppSpacing.xl)
                } else {
                    ForEach(viewModel.filteredEventsByMonth, id: \.month) { group in
                        monthSection(month: group.month, events: group.events)
                    }
                }
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, 0)
        }
        .background(Color.appBackground)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, viewModel: viewModel)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            TextField("Search events...", text: $viewModel.eventSearch)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
            if !viewModel.eventSearch.isEmpty {
                Button { viewModel.eventSearch = "" } label: {
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

    // MARK: - Month Section

    private func monthSection(month: Date, events: [MedicalEvent]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(monthHeader(month))
                .font(AppFont.headline())
                .foregroundStyle(Color.textPrimary)
                .padding(.leading, AppSpacing.xs)

            VStack(spacing: AppSpacing.sm) {
                ForEach(events) { event in
                    EventRowCard(event: event)
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text("No Events Yet")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text("Track doctor visits, lab tests, and upcoming medication events.")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text("No events found")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text("Try a different search term.")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper

    private func monthHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Event Row Card

struct EventRowCard: View {

    let event: MedicalEvent

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(typeColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: typeIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: AppSpacing.xs) {
                    if let provider = event.provider, !provider.isEmpty {
                        Text(provider)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.brandPrimary)
                    }
                    if event.provider != nil {
                        Text("•")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                    Text(dateDisplay)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Text(event.type.displayName)
                    .font(AppFont.caption())
                    .foregroundStyle(typeColor)
            }

            Spacer()

            if isUpcoming {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.semanticWarning)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private var isUpcoming: Bool { event.date > .now }

    private var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: event.date)
    }

    private var typeIcon: String {
        switch event.type {
        case .doctorVisit: return "stethoscope"
        case .test:        return "testtube.2"
        case .note:        return "note.text"
        case .other:       return "calendar"
        }
    }

    private var typeColor: Color {
        switch event.type {
        case .doctorVisit: return Color.brandPrimary
        case .test:        return Color.semanticInfo
        case .note:        return Color.semanticWarning
        case .other:       return Color.textSecondary
        }
    }
}
