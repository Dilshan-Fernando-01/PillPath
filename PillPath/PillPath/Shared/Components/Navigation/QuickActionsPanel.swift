//
//  QuickActionsPanel.swift
//  PillPath — Design System
//

import SwiftUI

enum QuickAction: CaseIterable {
    case settings, analytics, lookup, history, help

    var label: String {
        switch self {
        case .settings:  return "Settings"
        case .analytics: return "Analytics"
        case .lookup:    return "Lookup"
        case .history:   return "Dose History"
        case .help:      return "Help"
        }
    }

    var icon: String {
        switch self {
        case .settings:  return "gearshape"
        case .analytics: return "chart.bar"
        case .lookup:    return "magnifyingglass"
        case .history:   return "clock.arrow.circlepath"
        case .help:      return "questionmark.circle"
        }
    }
}

struct QuickActionsPanel: View {

    @Binding var isOpen: Bool
    var onAction: (QuickAction) -> Void = { _ in }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(AppFont.headline())
                .foregroundStyle(Color.brandPrimary)

            LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                ForEach(QuickAction.allCases, id: \.label) { action in
                    quickActionButton(action)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .appCardShadow()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func quickActionButton(_ action: QuickAction) -> some View {
        Button(action: {
            withAnimation { isOpen = false }
            onAction(action)
        }) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: action.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.brandPrimary)
                Text(action.label)
                    .font(AppFont.body())
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Tab Container

struct MainTabContainer: View {

    @State private var selectedTab: AppTab = .home
    @State private var isQuickActionsOpen = false
    @State private var showLookup = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showDoseHistory = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // Page content — fills the screen; safeAreaInset below reserves space for nav
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Dim overlay when quick actions open
            if isQuickActionsOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            isQuickActionsOpen = false
                        }
                    }
                    .transition(.opacity)
            }
        }
        // safeAreaInset keeps nav bar flush at bottom edge with no gap,
        // and ScrollViews in tab content automatically avoid it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if isQuickActionsOpen {
                    QuickActionsPanel(isOpen: $isQuickActionsOpen) { action in
                        handleQuickAction(action)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                BottomNavigationBar(
                    selectedTab: $selectedTab,
                    isQuickActionsOpen: $isQuickActionsOpen
                )
            }
            .background(Color.clear)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToHomeTab)) { _ in
            withAnimation { selectedTab = .home }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notif in
            if let tab = notif.object as? AppTab {
                withAnimation { selectedTab = tab }
            }
        }
        .fullScreenCover(isPresented: $showLookup) {
            LookupView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(SettingsViewModel())
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
        }
        .sheet(isPresented: $showDoseHistory) {
            DoseHistoryQuickAccess()
        }
    }

    // MARK: - Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:        HomeView()
        case .medications: MedicationsListView()
        case .scan:        OCRScanView()
        case .activity:    ScheduleView()
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .settings:  showSettings = true
        case .analytics: showInsights = true
        case .lookup:    showLookup = true
        case .history:   showDoseHistory = true
        case .help:      break
        }
    }
}

// MARK: - Dose History Quick-Access wrapper

private struct DoseHistoryQuickAccess: View {
    // @StateObject keeps the VM alive for the sheet's lifetime
    @StateObject private var vm = ActivityViewModel()
    var body: some View {
        DoseHistoryView(viewModel: vm)
    }
}

#Preview { MainTabContainer() }
