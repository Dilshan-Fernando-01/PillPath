//
//  QuickEditSheet.swift
//  PillPath — OCR Module
//
//  Step 6 from Figma: Quick inline editor for a scanned medication.
//  Shows: editable name, dosage field, schedule type chips, time-of-day chips.
//  "Done" → saves quick edits. "Advance Settings" → redirects to full stepper.
//

import SwiftUI

struct QuickEditSheet: View {

    let item: ScannedMedicationItem
    var onSave: (String, Double, DosageUnit) -> Void = { _, _, _ in }
    var onAdvanced: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var dosageAmount: Double
    @State private var dosageUnit: DosageUnit
    @State private var selectedSchedule: ScheduleFrequency = .daily
    @State private var selectedTimes: Set<DoseTimeLabel> = [.morning]

    init(item: ScannedMedicationItem,
         onSave: @escaping (String, Double, DosageUnit) -> Void,
         onAdvanced: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onAdvanced = onAdvanced
        _name         = State(initialValue: item.displayName)
        _dosageAmount = State(initialValue: item.suggestedDosageAmount)
        _dosageUnit   = State(initialValue: item.suggestedDosageUnit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    // Name field
                    FieldCard(label: "Medication Name") {
                        TextField("Name", text: $name)
                            .font(AppFont.body())
                            .padding(AppSpacing.md)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                    }

                    // Dosage
                    FieldCard(label: "Dosage") {
                        HStack(spacing: AppSpacing.md) {
                            // Amount stepper
                            HStack(spacing: AppSpacing.sm) {
                                Button {
                                    if dosageAmount > 0.5 { dosageAmount -= 0.5 }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 36, height: 36)
                                        .background(Color.brandPrimaryLight)
                                        .clipShape(Circle())
                                        .foregroundStyle(Color.brandPrimary)
                                }
                                .buttonStyle(.plain)

                                Text(dosageAmount.truncatingRemainder(dividingBy: 1) == 0
                                     ? String(Int(dosageAmount))
                                     : String(dosageAmount))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)
                                    .frame(minWidth: 40)

                                Button {
                                    dosageAmount += 0.5
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 36, height: 36)
                                        .background(Color.brandPrimaryLight)
                                        .clipShape(Circle())
                                        .foregroundStyle(Color.brandPrimary)
                                }
                                .buttonStyle(.plain)
                            }

                            // Unit selector
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(DosageUnit.allCases) { unit in
                                    let isSelected = dosageUnit == unit
                                    Button { dosageUnit = unit } label: {
                                        Text(unit.displayName)
                                            .font(AppFont.caption())
                                            .fontWeight(isSelected ? .semibold : .regular)
                                            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, 6)
                                            .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }

                    // Schedule type
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionLabel(text: "Schedule Type")
                        HStack(spacing: AppSpacing.sm) {
                            scheduleChip(.daily,        label: "Daily")
                            scheduleChip(.everyXHours,  label: "Interval")
                            scheduleChip(.specificDays, label: "Days")
                        }
                    }

                    // Time of day
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SectionLabel(text: "Time of Day")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                            ForEach([DoseTimeLabel.morning, .noon, .evening, .night]) { label in
                                timeChip(label)
                            }
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Edit \(item.originalName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: AppSpacing.sm) {
                    PrimaryButton(title: "Done") {
                        onSave(name, dosageAmount, dosageUnit)
                        dismiss()
                    }
                    TextLinkButton(title: "Advance Settings") {
                        onAdvanced()
                        dismiss()
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
                .background(Color.appBackground)
            }
        }
    }

    // MARK: - Schedule chip

    private func scheduleChip(_ freq: ScheduleFrequency, label: String) -> some View {
        let isSelected = selectedSchedule == freq
        return Button { selectedSchedule = freq } label: {
            Text(label)
                .font(AppFont.subheadline())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.brandPrimary : Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time chip

    private func timeChip(_ label: DoseTimeLabel) -> some View {
        let isSelected = selectedTimes.contains(label)
        return Button {
            if isSelected { selectedTimes.remove(label) }
            else { selectedTimes.insert(label) }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: label.systemIcon)
                    .font(.system(size: 13))
                Text(label.displayName)
                    .font(AppFont.subheadline())
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : Color.textSecondary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.brandPrimary : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
