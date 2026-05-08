

import SwiftUI

struct InsightsView: View {

    @StateObject private var viewModel = InsightsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {

             
                    periodPicker
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)

                   
                    if viewModel.period == .month {
                        monthNavigator
                            .padding(.horizontal, AppSpacing.md)
                    }

                  
                    adherenceCard
                        .padding(.horizontal, AppSpacing.md)

                    
                    statsRow
                        .padding(.horizontal, AppSpacing.md)

                   
                    activityChartCard
                        .padding(.horizontal, AppSpacing.md)

                   
                    if !viewModel.medicationStats.isEmpty {
                        medicationPerformanceSection
                            .padding(.horizontal, AppSpacing.md)
                    }

                   
                    if !viewModel.upcomingEvents.isEmpty {
                        upcomingEventsSection
                            .padding(.horizontal, AppSpacing.md)
                    }

              
                    tipsSection
                        .padding(.horizontal, AppSpacing.md)

                    Spacer().frame(height: 40)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Insights")
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
        .onAppear { viewModel.load() }
    }

  

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightsPeriod.allCases) { p in
                Button {
                    viewModel.changePeriod(p)
                } label: {
                    Text(p.displayName)
                        .font(AppFont.subheadline())
                        .fontWeight(viewModel.period == p ? .semibold : .regular)
                        .foregroundStyle(viewModel.period == p ? Color.brandPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            viewModel.period == p
                                ? Color.appSurface
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.appBorder.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }

            Spacer()

            Text(viewModel.selectedMonthLabel)
                .font(AppFont.subheadline())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.canGoForward ? Color.brandPrimary : Color.appBorder)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canGoForward)
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    

    private var adherenceCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("ADHERENCE RATE")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(1)

            Text("\(Int(viewModel.adherenceRate * 100))%")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(adherenceColor)

            Text(adherenceMotivation)
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private var adherenceColor: Color {
        let r = viewModel.adherenceRate
        if r >= 0.85 { return Color.semanticSuccess }
        if r >= 0.6  { return Color.semanticWarning }
        return Color.semanticError
    }

    private var adherenceMotivation: String {
        let r = viewModel.adherenceRate
        if r == 0    { return "No dose data for this period" }
        if r >= 0.95 { return "Perfect! You're crushing it 🌟" }
        if r >= 0.85 { return "Excellent progress this \(viewModel.period == .week ? "week" : "month")" }
        if r >= 0.7  { return "Good effort — keep it consistent" }
        if r >= 0.5  { return "Room to improve — you've got this!" }
        return "Let's get back on track together"
    }


    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            statMiniCard(label: "MISSED", value: "\(viewModel.missedCount)", color: Color.semanticError)
            statMiniCard(label: "TOTAL TAKEN", value: "\(viewModel.takenCount)", color: Color.semanticSuccess)
            statMiniCard(label: "STREAK", value: "\(viewModel.currentStreak)d", color: Color.brandPrimary)
        }
    }

    private func statMiniCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

   

    private var activityChartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("WEEKLY ACTIVITY")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(1)

           
            let stats = viewModel.period == .week
                ? viewModel.dailyStats
                : Array(viewModel.dailyStats.suffix(7)) 

            GeometryReader { geo in
                let maxVal = max(1, stats.map { $0.taken + $0.missed }.max() ?? 1)
                let barWidth = (geo.size.width - CGFloat(stats.count - 1) * 6) / CGFloat(stats.count)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(stats) { stat in
                        let totalH = geo.size.height * 0.75
                        let takenH = totalH * CGFloat(stat.taken) / CGFloat(maxVal)
                        let missedH = totalH * CGFloat(stat.missed) / CGFloat(maxVal)

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            if stat.missed > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.semanticError.opacity(0.7))
                                    .frame(width: barWidth, height: max(4, missedH))
                            }
                           
                            if stat.taken > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.semanticSuccess)
                                    .frame(width: barWidth, height: max(4, takenH))
                            }
                            if stat.taken == 0 && stat.missed == 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.appBorder)
                                    .frame(width: barWidth, height: 4)
                            }
                            Text(stat.shortLabel)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: barWidth)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .frame(height: 140)

  
            HStack(spacing: AppSpacing.md) {
                legendDot(color: Color.semanticSuccess, label: "Taken")
                legendDot(color: Color.semanticError.opacity(0.7), label: "Missed")
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
        }
    }



    private var medicationPerformanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("MEDICATION PERFORMANCE")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(1)

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.medicationStats) { stat in
                    medicationStatRow(stat)
                }
            }
        }
    }

    private func medicationStatRow(_ stat: MedicationStat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.name)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text(stat.dosageDisplay)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(stat.adherenceRate * 100))%")
                        .font(AppFont.body())
                        .fontWeight(.bold)
                        .foregroundStyle(stat.adherenceRate >= 0.8 ? Color.semanticSuccess : stat.adherenceRate >= 0.5 ? Color.semanticWarning : Color.semanticError)
                    if stat.missedCount > 0 {
                        Text("\(stat.missedCount) MISSED")
                            .font(AppFont.label())
                            .foregroundStyle(Color.semanticError)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stat.adherenceRate >= 0.8 ? Color.semanticSuccess : stat.adherenceRate >= 0.5 ? Color.semanticWarning : Color.semanticError)
                        .frame(width: geo.size.width * stat.adherenceRate, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }



    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("UPCOMING EVENTS")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(1)

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.upcomingEvents) { event in
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(Color.brandPrimaryLight)
                                .frame(width: 44, height: 44)
                            Image(systemName: eventIcon(event.type))
                                .font(.system(size: 18))
                                .foregroundStyle(Color.brandPrimary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(AppFont.body())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)
                            Text(event.date, style: .relative)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.semanticWarning)
                        }
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .appCardShadow()
                }
            }
        }
    }



    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("TRENDS & TIPS")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(1)

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.tips) { tip in
                    tipCard(tip)
                }
            }
        }
    }

    private func tipCard(_ tip: InsightTip) -> some View {
        HStack(spacing: AppSpacing.md) {
            Rectangle()
                .fill(tipColor(tip.accentColor))
                .frame(width: 4)
                .clipShape(Capsule())

            Image(systemName: tip.icon)
                .font(.system(size: 18))
                .foregroundStyle(tipColor(tip.accentColor))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tip.subtitle)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private func tipColor(_ accent: InsightAccent) -> Color {
        switch accent {
        case .warning: return Color.semanticWarning
        case .success: return Color.semanticSuccess
        case .info:    return Color.semanticInfo
        case .error:   return Color.semanticError
        }
    }

    private func eventIcon(_ type: MedicalEventType) -> String {
        switch type {
        case .doctorVisit: return "stethoscope"
        case .test:        return "testtube.2"
        case .note:        return "note.text"
        case .other:       return "calendar"
        }
    }
}
