
import SwiftUI

struct DoseHistoryView: View {

    @ObservedObject var viewModel: ActivityViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: HistoryPeriod = .week
    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }()

    enum HistoryPeriod: CaseIterable, Identifiable {
        case week, month
        var id: Self { self }
        var displayName: String { self == .week ? "Last 7 Days" : "By Month" }
    }

    private var canGoForward: Bool {
        let cal = Calendar.current
        return cal.compare(selectedMonth, to: .now, toGranularity: .month) == .orderedAscending
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(HistoryPeriod.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(AppSpacing.md)
                .onChange(of: selectedPeriod) { _, _ in loadHistory() }

                if selectedPeriod == .month {
                    monthNavigator
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)
                }

                if viewModel.historyItems.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Dose History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
        .onAppear { loadHistory() }
    }


    private var monthNavigator: some View {
        HStack {
            Button { previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
                    .appCardShadow()
            }

            Spacer()

            Text(monthLabel)
                .font(AppFont.subheadline())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button { nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoForward ? Color.brandPrimary : Color.appBorder)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
                    .appCardShadow()
            }
            .disabled(!canGoForward)
        }
    }


    private var historyList: some View {
        ScrollView {
            let outOfWindow = viewModel.historyItems.filter(\.isOutOfWindow)
            if !outOfWindow.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.semanticWarning)
                    Text("\(outOfWindow.count) dose\(outOfWindow.count == 1 ? "" : "s") confirmed outside their scheduled time window.")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticWarning)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(Color.semanticWarning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
            }

            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(groupedByDate, id: \.date) { group in
                    Section {
                        ForEach(group.items) { item in
                            historyRow(item)
                        }
                    } header: {
                        Text(dateHeader(group.date))
                            .font(AppFont.label())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)
                            .kerning(0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 40)
        }
    }


    private func historyRow(_ item: ActivityViewModel.DoseHistoryItem) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor(item.status).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: statusIcon(item.status))
                    .font(.system(size: 16))
                    .foregroundStyle(statusColor(item.status))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.medicationName)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: AppSpacing.xs) {
                    Text("Scheduled: \(formattedTime(item.scheduledAt)) (\(item.scheduledLabel.displayName))")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                if let takenAt = item.takenAt {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(item.isOutOfWindow ? Color.semanticWarning : Color.semanticSuccess)
                        Text("Confirmed: \(formattedTime(takenAt)) (\(item.takenLabel?.displayName ?? ""))")
                            .font(AppFont.caption())
                            .foregroundStyle(item.isOutOfWindow ? Color.semanticWarning : Color.semanticSuccess)
                    }
                }

                if item.isOutOfWindow, let takenLabel = item.takenLabel {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.semanticWarning)
                        Text("Confirmed in \(takenLabel.displayName) — scheduled for \(item.scheduledLabel.displayName)")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.semanticWarning)
                    }
                }
            }

            Spacer()

            Text(item.status.displayName)
                .font(AppFont.caption())
                .fontWeight(.medium)
                .foregroundStyle(statusColor(item.status))
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 3)
                .background(statusColor(item.status).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(AppSpacing.md)
        .background(item.isOutOfWindow ? Color.semanticWarning.opacity(0.05) : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            item.isOutOfWindow
                ? RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.semanticWarning.opacity(0.3), lineWidth: 1)
                : nil
        )
        .appCardShadow()
    }


    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Color.textSecondary.opacity(0.4))
            Text("No history yet")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text("Dose history for the selected period will appear here.")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }


    private var groupedByDate: [(date: Date, items: [ActivityViewModel.DoseHistoryItem])] {
        let calendar = Calendar.current
        var groups: [(date: Date, items: [ActivityViewModel.DoseHistoryItem])] = []
        var seen: [Date: Int] = [:]
        for item in viewModel.historyItems {
            let day = calendar.startOfDay(for: item.scheduledAt)
            if let idx = seen[day] {
                groups[idx].items.append(item)
            } else {
                seen[day] = groups.count
                groups.append((date: day, items: [item]))
            }
        }
        return groups
    }

    private func dateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date)     { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func statusColor(_ status: DoseStatus) -> Color {
        switch status {
        case .taken:   return Color.semanticSuccess
        case .missed:  return Color.semanticError
        case .skipped: return Color.textSecondary
        case .pending: return Color.semanticWarning
        }
    }

    private func statusIcon(_ status: DoseStatus) -> String {
        switch status {
        case .taken:   return "checkmark.circle.fill"
        case .missed:  return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        case .pending: return "clock.fill"
        }
    }


    private func previousMonth() {
        let cal = Calendar.current
        selectedMonth = cal.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        loadHistory()
    }

    private func nextMonth() {
        guard canGoForward else { return }
        let cal = Calendar.current
        selectedMonth = cal.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        loadHistory()
    }

    private func loadHistory() {
        let cal = Calendar.current
        let end: Date
        let start: Date

        switch selectedPeriod {
        case .week:
            end   = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: .now))!
            start = cal.date(byAdding: .day, value: -7, to: end)!
        case .month:
            let comps = cal.dateComponents([.year, .month], from: selectedMonth)
            let firstDay = cal.date(from: comps) ?? cal.startOfDay(for: .now)
            start = firstDay
            end   = cal.date(byAdding: DateComponents(month: 1), to: firstDay) ?? firstDay
        }

        viewModel.loadMedications()
        viewModel.loadHistory(from: start, to: end)
    }
}
