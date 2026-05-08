

import Foundation
import Combine



enum InsightsPeriod: CaseIterable, Identifiable {
    case week, month
    var id: Self { self }
    var displayName: String { self == .week ? "This Week" : "This Month" }
    var days: Int { self == .week ? 7 : 30 }
}

struct DailyBarData: Identifiable {
    let id = UUID()
    let day: Date
    let taken: Int
    let missed: Int
    let skipped: Int

    var total: Int { taken + missed + skipped }

    var shortLabel: String {
        let f = DateFormatter()
        f.dateFormat = self.taken + self.missed + self.skipped > 0 ? "EEE" : "EEE"
        f.dateFormat = "EEE"
        return String(f.string(from: day).prefix(3)).uppercased()
    }
}

struct MedicationStat: Identifiable {
    let id = UUID()
    let medicationId: UUID
    let name: String
    let dosageDisplay: String
    let takenCount: Int
    let totalScheduled: Int
    let missedCount: Int

    var adherenceRate: Double {
        totalScheduled == 0 ? 0 : Double(takenCount) / Double(totalScheduled)
    }
}

struct InsightTip: Identifiable {
    let id = UUID()
    let icon: String
    let accentColor: InsightAccent
    let title: String
    let subtitle: String
}

enum InsightAccent {
    case warning, success, info, error
}


@MainActor
final class InsightsViewModel: ObservableObject {

    @Published var period: InsightsPeriod = .week
    @Published var selectedMonth: Date = Calendar.current.startOfDay(for: .now)
    @Published var isLoading = false

    var selectedMonthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    var canGoForward: Bool {
        Calendar.current.compare(selectedMonth, to: .now, toGranularity: .month) == .orderedAscending
    }


    @Published var takenCount: Int = 0
    @Published var missedCount: Int = 0
    @Published var skippedCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var adherenceRate: Double = 0   

  
    @Published var dailyStats: [DailyBarData] = []


    @Published var medicationStats: [MedicationStat] = []

  
    @Published var tips: [InsightTip] = []

  
    @Published var upcomingEvents: [MedicalEvent] = []


    private let doseService: DoseTrackingServiceProtocol
    private let medService: MedicationServiceProtocol
    private let eventService: EventServiceProtocol

    init(
        doseService: DoseTrackingServiceProtocol? = nil,
        medService: MedicationServiceProtocol? = nil,
        eventService: EventServiceProtocol? = nil
    ) {
        self.doseService  = doseService  ?? DIContainer.shared.resolve(DoseTrackingServiceProtocol.self)
        self.medService   = medService   ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
        self.eventService = eventService ?? DIContainer.shared.resolve(EventServiceProtocol.self)
    }

   

    func load() {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: .now)
        let (start, end): (Date, Date)
        if period == .month {
            let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
            let firstDay = calendar.date(from: comps) ?? today
            let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) ?? today
            start = firstDay
            end = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
        } else {
            let weekStart = calendar.date(byAdding: .day, value: -(period.days - 1), to: today)!
            start = weekStart
            end = calendar.date(byAdding: .day, value: 1, to: today)!
        }

        do {
            let logs = try doseService.fetchLogs(from: start, to: end)
            let meds = try medService.fetchAll()
            let medMap = Dictionary(uniqueKeysWithValues: meds.map { ($0.id, $0) })

            computeSummary(logs: logs)
            computeDailyStats(logs: logs, start: start, calendar: calendar)
            computeMedicationStats(logs: logs, medMap: medMap)
            computeStreak(calendar: calendar, today: today)
            computeTips(logs: logs, medMap: medMap, calendar: calendar)
            loadUpcomingEvents()
        } catch {
            
        }
    }

    func changePeriod(_ p: InsightsPeriod) {
        period = p
        load()
    }

    func previousMonth() {
        let cal = Calendar.current
        selectedMonth = cal.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        if period != .month { period = .month }
        load()
    }

    func nextMonth() {
        guard canGoForward else { return }
        let cal = Calendar.current
        selectedMonth = cal.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        load()
    }


    private func computeSummary(logs: [DoseLog]) {
        takenCount   = logs.filter { $0.status == .taken }.count
        missedCount  = logs.filter { $0.status == .missed }.count
        skippedCount = logs.filter { $0.status == .skipped }.count
        let total    = takenCount + missedCount
        adherenceRate = total == 0 ? 0 : Double(takenCount) / Double(total)
    }

    private func computeDailyStats(logs: [DoseLog], start: Date, calendar: Calendar) {
        var result: [DailyBarData] = []
        let numDays: Int
        if period == .month {
            let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
            let firstDay = calendar.date(from: comps) ?? start
            numDays = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30
        } else {
            numDays = period.days
        }
        for offset in 0..<numDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dayLogs = logs.filter { calendar.isDate($0.scheduledAt, inSameDayAs: day) }
            result.append(DailyBarData(
                day:     day,
                taken:   dayLogs.filter { $0.status == .taken }.count,
                missed:  dayLogs.filter { $0.status == .missed }.count,
                skipped: dayLogs.filter { $0.status == .skipped }.count
            ))
        }
        dailyStats = result
    }

    private func computeMedicationStats(logs: [DoseLog], medMap: [UUID: Medication]) {
        var groups: [UUID: [DoseLog]] = [:]
        for log in logs {
            groups[log.medicationId, default: []].append(log)
        }
        medicationStats = groups.compactMap { (medId, medLogs) -> MedicationStat? in
            guard let med = medMap[medId] else { return nil }
            let taken   = medLogs.filter { $0.status == .taken }.count
            let missed  = medLogs.filter { $0.status == .missed }.count
            let total   = taken + missed
            return MedicationStat(
                medicationId:   medId,
                name:           med.name,
                dosageDisplay:  med.dosageDisplay,
                takenCount:     taken,
                totalScheduled: total,
                missedCount:    missed
            )
        }.sorted { $0.adherenceRate > $1.adherenceRate }
    }

    private func computeStreak(calendar: Calendar, today: Date) {
        var streak = 0
        var checkDate = today
        while true {
            let dayLogs: [DoseLog]
            do { dayLogs = try doseService.fetchLogs(on: checkDate) } catch { break }
            if dayLogs.isEmpty { break }
            let hasMissed = dayLogs.contains { $0.status == .missed }
            if hasMissed { break }
            let allDone = dayLogs.allSatisfy { $0.status == .taken || $0.status == .skipped }
            if !allDone { break }
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
            if streak > 365 { break }
        }
        currentStreak = streak
    }

    private func computeTips(logs: [DoseLog], medMap: [UUID: Medication], calendar: Calendar) {
        var result: [InsightTip] = []

        let missedLogs = logs.filter { $0.status == .missed }
        if !missedLogs.isEmpty {
            var labelCounts: [DoseTimeLabel: Int] = [:]
            for log in missedLogs {
                let h = calendar.component(.hour, from: log.scheduledAt)
                let label = DoseTimeLabel.from(hour: h)
                labelCounts[label, default: 0] += 1
            }
            if let worstLabel = labelCounts.max(by: { $0.value < $1.value })?.key, labelCounts[worstLabel]! > 1 {
                result.append(InsightTip(
                    icon: worstLabel.systemIcon,
                    accentColor: .warning,
                    title: "You miss more \(worstLabel.displayName.lowercased()) medications.",
                    subtitle: "Try setting a \(worstLabel.displayName.lowercased()) alarm \(worstLabel == .morning ? "15 minutes" : "30 minutes") earlier."
                ))
            }
        }

       if currentStreak >= 7 {
            result.append(InsightTip(
                icon: "flame.fill",
                accentColor: .success,
                title: "\(currentStreak)-day streak! Keep it up.",
                subtitle: "You haven't missed a dose in \(currentStreak) days. Excellent consistency!"
            ))
        } else if currentStreak == 0 && !logs.isEmpty {
            result.append(InsightTip(
                icon: "arrow.counterclockwise",
                accentColor: .info,
                title: "Start a new streak today.",
                subtitle: "Take all your medications today to begin building your streak."
            ))
        }

       if let best = medicationStats.first, best.adherenceRate > 0.9 && medicationStats.count > 1 {
            let bestName = medMap[best.medicationId]?.name ?? best.name
            result.append(InsightTip(
                icon: "sun.max.fill",
                accentColor: .success,
                title: "\(bestName) adherence is very high (\(Int(best.adherenceRate * 100))%).",
                subtitle: "Great job maintaining your \(bestName) routine!"
            ))
        }

      if let worst = medicationStats.last, worst.adherenceRate < 0.6 && worst.totalScheduled > 2 {
            let worstName = medMap[worst.medicationId]?.name ?? worst.name
            result.append(InsightTip(
                icon: "exclamationmark.triangle.fill",
                accentColor: .error,
                title: "\(worstName) needs attention (\(Int(worst.adherenceRate * 100))%).",
                subtitle: "You've missed \(worst.missedCount) dose\(worst.missedCount == 1 ? "" : "s"). Consider setting a stronger reminder."
            ))
        }

      
        if adherenceRate >= 0.9 && takenCount >= 5 {
            result.append(InsightTip(
                icon: "checkmark.seal.fill",
                accentColor: .success,
                title: "Outstanding overall adherence this \(period == .week ? "week" : "month").",
                subtitle: "You're in the top tier of medication consistency. Keep it up!"
            ))
        } else if adherenceRate > 0 && adherenceRate < 0.5 {
            result.append(InsightTip(
                icon: "heart.fill",
                accentColor: .warning,
                title: "Consistency is key for your health.",
                subtitle: "Aim to take each dose within 2 hours of the scheduled time for best results."
            ))
        }

        tips = result.isEmpty ? [
            InsightTip(
                icon: "chart.bar.fill",
                accentColor: .info,
                title: "No data yet for this period.",
                subtitle: "Add medications and track doses to see your personalised insights."
            )
        ] : result
    }

    private func loadUpcomingEvents() {
        let all = (try? eventService.fetchAll()) ?? []
        let now = Date.now
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        upcomingEvents = all
            .filter { $0.date >= now && $0.date <= sevenDaysLater }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map { $0 }
    }
}
