//
//  DoseDisplayItem.swift
//  PillPath — Home Module
//
//  Flat display model assembled by HomeViewModel.
//  Combines schedule + medication + log data into one object the View consumes.
//

import Foundation



struct DoseDisplayItem: Identifiable, Equatable {
    let id: UUID                   
    let medicationId: UUID
    let scheduleId: UUID
    let medicationName: String
    let dosageDisplay: String       
    let medicationCategory: String? 
    let usageNote: String?         
    let scheduledAt: Date
    let timeLabel: DoseTimeLabel
    let mealTiming: MealTiming
    var status: DoseStatus
    var logId: UUID?               

    var isTaken:  Bool { status == .taken }
    var isMissed: Bool { status == .missed }
    var isPending: Bool { status == .pending }


    var isFutureScheduled: Bool {
        Date.now < scheduledAt
    }

   
    var isLate: Bool {
        guard status == .pending else { return false }
        return Date.now > scheduledAt && !shouldShowAsMissed
    }

   
    var shouldShowAsMissed: Bool {
        guard status == .pending else { return false }
        return Date.now > scheduledAt.addingTimeInterval(3600) 
    }

    var effectiveStatus: DoseStatus {
        shouldShowAsMissed ? .missed : status
    }
}



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



struct MealTimingGroup: Identifiable {
    let id: MealTiming
    let timing: MealTiming
    var items: [DoseDisplayItem]
    var isEmpty: Bool { items.isEmpty }
}
