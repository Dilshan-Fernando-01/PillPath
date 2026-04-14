//
//  CalendarStripView.swift
//  PillPath — Home Module
//


import SwiftUI

struct CalendarStripView: View {

    @Binding var selectedDate: Date
    var onDateSelected: (Date) -> Void = { _ in }

    private let calendar = Calendar.current
    private let dates: [Date] = {
        let today = Calendar.current.startOfDay(for: .now)
        return (-30...30).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(dates, id: \.self) { date in
                        DayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                            .id(date)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = date
                                }
                                onDateSelected(date)
                            }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }
            .onAppear {
                let today = calendar.startOfDay(for: .now)
                proxy.scrollTo(today, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
    }
}


private struct DayCell: View {

    let date: Date
    let isSelected: Bool

    private let calendar = Calendar.current

    private var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var weekdayShort: String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(weekdayShort)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : Color.textSecondary)

            Text(dayNumber)
                .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : (isToday ? Color.brandPrimary : Color.textPrimary))


            Circle()
                .fill(isSelected ? Color.white.opacity(0.6) : (isToday ? Color.brandPrimary : Color.clear))
                .frame(width: 5, height: 5)
        }
        .frame(width: 50, height: 68)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [Color.gradientStart, Color.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.appSurface
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(isToday && !isSelected ? Color.brandPrimary.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .appCardShadow()
    }
}

#Preview {
    @State var date = Calendar.current.startOfDay(for: .now)
    return CalendarStripView(selectedDate: $date)
        .background(Color.appBackground)
}
