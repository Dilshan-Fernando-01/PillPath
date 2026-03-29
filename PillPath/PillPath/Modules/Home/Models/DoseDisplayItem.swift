//
//  DoseDisplayItem.swift
//  PillPath — Home Module
//
//  Flat display model assembled by HomeViewModel.
//  Combines schedule + medication + log data into one object the View consumes.
//

import Foundation

// MARK: - DoseDisplayItem

struct DoseDisplayItem: Identifiable, Equatable {
    let id: UUID                    // log.id if a log exists, otherwise generated
    let medicationId: UUID
    let scheduleId: UUID
    let medicationName: String
    let dosageDisplay: String       // e.g. "1 Tablet"
    let medicationCategory: String? // e.g. "Blood Pressure" (from instructions)
    let usageNote: String?          // e.g. "Only take if you have pain" (from notes)
    let scheduledAt: Date
    let timeLabel: DoseTimeLabel
    let mealTiming: MealTiming
    var status: DoseStatus
    var logId: UUID?                // nil if no DoseLog record exists yet

    var isTaken:  Bool { status == .taken }
    var isMissed: Bool { status == .missed }
    var isPending: Bool { status == .pending }

    /// A dose is displayable-as-missed when it's past the grace period and still pending
    var shouldShowAsMissed: Bool {
        guard status == .pending else { return false }
        return Date.now > scheduledAt.addingTimeInterval(3600) // 1-hour grace
    }

    var effectiveStatus: DoseStatus {
        shouldShowAsMissed ? .missed : status
    }
}

// MARK: - TimeOfDayGroup

struct TimeOfDayGroup: Identifiable {
    let id: DoseTimeLabel
    let label: DoseTimeLabel
    var mealGroups: [MealTimingGroup]

    var allItems: [DoseDisplayItem]  { mealGroups.flatMap(\.items) }
    var isEmpty: Bool                { allItems.isEmpty }
    var hasMissed: Bool              { allItems.contains { $0.effectiveStatus == .missed } }
    var allTaken: Bool               { !allItems.isEmpty && allItems.allSatisfy(\.isTaken) }
    var pendingCount: Int            { allItems.filter(\.isPending).count }
}

// MARK: - MealTimingGroup

struct MealTimingGroup: Identifiable {
    let id: MealTiming
    let timing: MealTiming
    var items: [DoseDisplayItem]
    var isEmpty: Bool { items.isEmpty }
}
