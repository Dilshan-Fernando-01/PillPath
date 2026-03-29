//
//  FullScheduleSheet.swift
//  PillPath — Home Module
//
//  Bottom sheet showing all time-of-day groups for the selected date.
//  Triggered by "View Full Schedule of the Day".
//

import SwiftUI

struct FullScheduleSheet: View {

    let groups: [TimeOfDayGroup]
    var onMarkTaken: (DoseDisplayItem) -> Void = { _ in }
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.lg) {
                    ForEach(groups) { group in
                        TimeOfDayGroupSection(group: group, onMarkTaken: onMarkTaken)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Today's Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { isPresented = false }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }
}
