//
//  AddMedStep4ScheduleView.swift
//  PillPath — Medications Module
//
//  Step 4: Choose schedule frequency + configure sub-options per type.
//

import SwiftUI

struct AddMedStep4ScheduleView: View {

    @ObservedObject var viewModel: AddMedicationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "How often is it taken?",
                subtitle: "Choose a schedule that matches your prescription."
            )

            // Frequency selector list
            VStack(spacing: AppSpacing.sm) {
                ForEach(ScheduleFrequency.allCases) { freq in
                    frequencyRow(freq)
                }
            }

            // Sub-options panel for selected frequency
            Group {
                switch viewModel.frequency {
                case .everyXHours:   intervalSubOptions
                case .specificDays:  specificDaysSubOptions
                case .custom:        customDatesSubOptions
                default:             EmptyView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: viewModel.frequency)

            Spacer()
        }
    }

    // MARK: - Frequency Row

    private func frequencyRow(_ freq: ScheduleFrequency) -> some View {
        let isSelected = viewModel.frequency == freq
        return Button {
            withAnimation { viewModel.frequency = freq }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 40, height: 40)
                    Image(systemName: freq.systemIcon)
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(freq.displayName)
                        .font(AppFont.subheadline())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Text(frequencySubtitle(freq))
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.appBorder)
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func frequencySubtitle(_ freq: ScheduleFrequency) -> String {
        switch freq {
        case .daily:         return "Same time(s) every day"
        case .everyXHours:   return "Set a custom interval (e.g. every 6 hours)"
        case .specificDays:  return "Choose days of the week"
        case .alternateDays: return "Every other day"
        case .custom:        return "Pick specific dates from a calendar"
        }
    }

    // MARK: - Every X Hours Sub-Options

    private var intervalSubOptions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Interval")

            VStack(spacing: AppSpacing.md) {
                // Hours picker
                HStack {
                    Text("Hours")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Picker("Hours", selection: $viewModel.intervalHours) {
                        ForEach(1...23, id: \.self) { h in
                            Text("\(h) hr").tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.brandPrimary)
                }

                Divider()

                // Minutes picker
                HStack {
                    Text("Minutes")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Picker("Minutes", selection: $viewModel.intervalMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { m in
                            Text("\(m) min").tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.brandPrimary)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )

            // Preview
            let totalHours = viewModel.intervalHours
            let totalMins  = viewModel.intervalMinutes
            let label = totalMins > 0 ? "Every \(totalHours)h \(totalMins)m" : "Every \(totalHours) hours"
            Text("Schedule: \(label)")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Specific Days Sub-Options

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var specificDaysSubOptions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Select Days")

            HStack(spacing: AppSpacing.xs) {
                ForEach(0..<7) { index in
                    let isSelected = viewModel.specificDays.contains(index)
                    Button {
                        withAnimation {
                            if isSelected { viewModel.specificDays.remove(index) }
                            else { viewModel.specificDays.insert(index) }
                        }
                    } label: {
                        Text(dayNames[index])
                            .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(isSelected ? Color.brandPrimary : Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !viewModel.specificDays.isEmpty {
                let selected = viewModel.specificDays.sorted().map { dayNames[$0] }.joined(separator: ", ")
                Text("Selected: \(selected)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Custom Dates Sub-Options

    @State private var showDatePicker = false
    @State private var pickerDate = Date.now

    private var customDatesSubOptions: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Custom Dates")

            // Selected dates list
            if !viewModel.customDates.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.customDates, id: \.self) { date in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.brandPrimary)
                                .frame(width: 20)
                            Text(date.formatted(.dateTime.day().month().year()))
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Button {
                                viewModel.customDates.removeAll { $0 == date }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.semanticError)
                            }
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                        if date != viewModel.customDates.last {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appCardShadow()
            }

            // Date picker inline
            if showDatePicker {
                VStack(spacing: AppSpacing.sm) {
                    DatePicker("", selection: $pickerDate, in: Date.now..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.brandPrimary)

                    HStack(spacing: AppSpacing.sm) {
                        SecondaryButton(title: "Cancel") { showDatePicker = false }
                        PrimaryButton(title: "Add Date") {
                            let cal = Calendar.current
                            let normalized = cal.startOfDay(for: pickerDate)
                            if !viewModel.customDates.contains(normalized) {
                                viewModel.customDates.append(normalized)
                                viewModel.customDates.sort()
                            }
                            showDatePicker = false
                        }
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appCardShadow()
            } else {
                Button {
                    showDatePicker = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                        Text("Add Date")
                            .font(AppFont.subheadline())
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.brandPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
