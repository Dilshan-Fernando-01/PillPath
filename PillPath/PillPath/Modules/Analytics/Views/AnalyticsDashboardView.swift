//
//  AnalyticsDashboardView.swift
//  PillPath — Analytics Module
//
//  Placeholder — UI will be implemented from Figma design.
//

import SwiftUI

struct AnalyticsDashboardView: View {

    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            // TODO: Replace with Figma design (charts + adherence summary)
            Text("Analytics — coming soon")
                .foregroundStyle(.secondary)
                .navigationTitle("Analytics")
        }
        .onAppear { viewModel.loadAnalytics() }
    }
}

#Preview { AnalyticsDashboardView() }
