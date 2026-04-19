//
//  BottomNavigationBar.swift
//  PillPath — Design System
//
//  Custom tab bar matching Figma: HOME | MEDS | [FAB] | SCAN | ACTIVITY
//  The centre + button expands into a QuickActionsPanel overlay.
//

import SwiftUI

// MARK: - Tab Enum

enum AppTab: CaseIterable {
    case home, medications, scan, activity

    var label: String {
        switch self {
        case .home:         return "HOME"
        case .medications:  return "MEDS"
        case .scan:         return "SCAN"
        case .activity:     return "ACTIVITY"
        }
    }

    var icon: String {
        switch self {
        case .home:        return "house"
        case .medications: return "cross.circle"
        case .scan:        return "qrcode.viewfinder"
        case .activity:    return "calendar"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:        return "house.fill"
        case .medications: return "cross.circle.fill"
        case .scan:        return "qrcode.viewfinder"
        case .activity:    return "calendar.fill"
        }
    }
}

// MARK: - Bottom Navigation Bar

struct BottomNavigationBar: View {

    @Binding var selectedTab: AppTab
    @Binding var isQuickActionsOpen: Bool

    var body: some View {
        ZStack {
            // Tab bar background
            HStack(spacing: 0) {
                ForEach([AppTab.home, .medications], id: \.label) { tab in
                    tabItem(tab)
                }

                // FAB placeholder space
                Spacer().frame(width: 72)

                ForEach([AppTab.scan, .activity], id: \.label) { tab in
                    tabItem(tab)
                }
            }
            .frame(height: 64)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appCardShadow()

            // Centre FAB
            Button(action: {
                withAnimation(.spring(duration: 0.3)) {
                    isQuickActionsOpen.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: 56, height: 56)
                        .appButtonShadow()
                    Image(systemName: isQuickActionsOpen ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isQuickActionsOpen ? 45 : 0))
                        .animation(.spring(duration: 0.3), value: isQuickActionsOpen)
                }
            }
            .offset(y: -16)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Tab Item

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                Text(tab.label)
                    .font(AppFont.label())
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @State var tab: AppTab = .home
    @State var open = false
    return ZStack(alignment: .bottom) {
        Color.appBackground.ignoresSafeArea()
        BottomNavigationBar(selectedTab: $tab, isQuickActionsOpen: $open)
    }
}
