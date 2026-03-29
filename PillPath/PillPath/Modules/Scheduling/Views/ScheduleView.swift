//
//  ScheduleView.swift
//  PillPath — Scheduling Module
//
//  Activity screen — 3-tab container:
//    [Schedule] | [Medications] | [Events]
//

import SwiftUI

struct ScheduleView: View {

    @StateObject private var viewModel = ActivityViewModel()
    @State private var selectedTab: ActivityTab = .schedule
    @State private var showAddEvent = false

    enum ActivityTab: String, CaseIterable {
        case schedule    = "Schedule"
        case medications = "Medications"
        case events      = "Events"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom tab bar
                tabSelector
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xs)

                Divider()
                    .foregroundStyle(Color.appBorder)

                // Tab content
                Group {
                    switch selectedTab {
                    case .schedule:
                        ActivityScheduleTab(viewModel: viewModel)
                    case .medications:
                        ActivityMedicationsTab(viewModel: viewModel)
                    case .events:
                        ActivityEventsTab(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedTab == .events {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddEvent = true
                        } label: {
                            Label("Add Event", systemImage: "plus.circle.fill")
                                .font(AppFont.body())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.brandPrimary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEvent, onDismiss: { viewModel.loadEvents() }) {
            EventFormView(viewModel: viewModel)
        }
        .onAppear { viewModel.loadAll() }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(ActivityTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(AppFont.subheadline())
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundStyle(selectedTab == tab ? Color.appSurface : Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == tab ? Color.brandPrimary : Color.appSurface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.full)
                                .stroke(selectedTab == tab ? Color.clear : Color.appBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.full)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ScheduleView()
        .environmentObject(SettingsViewModel())
}
