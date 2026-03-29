//
//  AnalyticsViewModel.swift
//  PillPath — Analytics Module
//

import Foundation
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {

    @Published var records: [AdherenceRecord] = []
    @Published var overallAdherence: Double = 0
    @Published var selectedPeriod: AnalyticsPeriod = .lastSevenDays
    @Published var errorMessage: String?

    private let service: AnalyticsServiceProtocol

    init(service: AnalyticsServiceProtocol? = nil) {
        self.service = service ?? DIContainer.shared.resolve(AnalyticsServiceProtocol.self)
    }

    func loadAnalytics() {
        do {
            let interval = selectedPeriod.dateInterval
            records = try service.adherenceRecords(for: interval)
            overallAdherence = try service.overallAdherence(for: interval)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case lastSevenDays   = "Last 7 Days"
    case lastThirtyDays  = "Last 30 Days"
    case lastNinetyDays  = "Last 90 Days"

    var dateInterval: DateInterval {
        let now = Date.now
        switch self {
        case .lastSevenDays:   return DateInterval(start: now.addingTimeInterval(-7 * 86400), end: now)
        case .lastThirtyDays:  return DateInterval(start: now.addingTimeInterval(-30 * 86400), end: now)
        case .lastNinetyDays:  return DateInterval(start: now.addingTimeInterval(-90 * 86400), end: now)
        }
    }
}
