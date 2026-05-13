

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



struct MainTabContainer: View {

    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var backupVM = BackupViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .home
    @State private var isQuickActionsOpen = false
    @State private var showLookup = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showDoseHistory = false
    @State private var showHelp = false
    @State private var restoreToken = 0

    var body: some View {
        ZStack(alignment: .bottom) {

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .task {
            await backupVM.checkRestorePromptNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task { await backupVM.autoBackupIfNeeded() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataRestored)) { _ in
            restoreToken += 1
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
                .environmentObject(settings)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
        }
        .sheet(isPresented: $showDoseHistory) {
            DoseHistoryQuickAccess()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .appModal(
            isPresented: $backupVM.showRestorePrompt,
            icon: .info,
            title: "Cloud Backup Found",
            message: "A backup was found in the cloud for your account. Would you like to restore it now?",
            primaryButton: .primary("Restore") {
                Task { await backupVM.restore() }
            },
            secondaryButton: .cancel()
        )
    }

  

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:        HomeView()     .id("home-\(restoreToken)")
        case .medications: MedicationsListView()
        case .scan:        OCRScanView()
        case .activity:    ScheduleView() .id("schedule-\(restoreToken)")
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .settings:  showSettings = true
        case .analytics: showInsights = true
        case .lookup:    showLookup = true
        case .history:   showDoseHistory = true
        case .help:      showHelp = true
        }
    }
}



private struct DoseHistoryQuickAccess: View {

    @StateObject private var vm = ActivityViewModel()
    var body: some View {
        DoseHistoryView(viewModel: vm)
    }
}

#Preview { MainTabContainer() }
