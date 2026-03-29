//
//  DoseItemRow.swift
//  PillPath — Home Module
//
//  Single medication row inside a meal-timing card.
//  Matches Figma: pill icon | name + detail | circle checkbox.
//

import SwiftUI

struct DoseItemRow: View {

    let item: DoseDisplayItem
    var onMarkTaken: () -> Void = {}
    var onUndoTaken: () -> Void = {}

    @State private var showUndoConfirm = false
    @State private var showTimingConfirm = false

    private var currentTimeLabel: DoseTimeLabel {
        DoseTimeLabel.from(hour: Calendar.current.component(.hour, from: .now))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // "TAKE NOW" banner — shown only for pending items in the current time window
            if item.effectiveStatus == .pending && currentTimeLabel == item.timeLabel {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 11))
                    Text("Time to take this medication")
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.brandPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, 10)
                .padding(.bottom, 2)
            }

            HStack(spacing: AppSpacing.md) {

                // Pill icon
                pillIcon

                // Name + subtitle + time
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.medicationName)
                        .font(AppFont.headline())   // larger for elderly
                        .fontWeight(.semibold)
                        .foregroundStyle(labelColor)

                    // Scheduled time + dosage
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                        Text(scheduledTimeDisplay)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        if !item.dosageDisplay.isEmpty {
                            Text("·")
                                .foregroundStyle(Color.textSecondary)
                            Text(item.dosageDisplay)
                                .font(AppFont.body())
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    if let cat = item.medicationCategory, !cat.isEmpty {
                        Text(cat)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary.opacity(0.7))
                    }
                }

                Spacer()

                // Status control — larger tap target
                statusControl
            }

            // Usage note (e.g. "Only take if you have pain")
            if let note = item.usageNote, !note.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.semanticWarning)
                    Text(note)
                        .font(AppFont.body())
                        .foregroundStyle(Color.semanticWarning)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 60) // align with text column
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
        .confirmationDialog(
            "Undo taken for \(item.medicationName)?",
            isPresented: $showUndoConfirm,
            titleVisibility: .visible
        ) {
            Button("Undo Taken", role: .destructive) { onUndoTaken() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Mark as taken outside scheduled time?",
            isPresented: $showTimingConfirm,
            titleVisibility: .visible
        ) {
            Button("Mark as Taken") { onMarkTaken() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(item.medicationName) is scheduled for \(item.timeLabel.displayName). You're confirming it during \(currentTimeLabel.displayName). This will be logged with the actual time.")
        }
    }

    // MARK: - Sub-views

    private var pillIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
                .frame(width: 50, height: 50)
            Image(systemName: iconName)
                .font(.system(size: 22))
                .foregroundStyle(iconForeground)
        }
    }

    private var statusControl: some View {
        Group {
            switch item.effectiveStatus {
            case .taken:
                Button { showUndoConfirm = true } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.semanticSuccess)
                        Text("Taken")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.semanticSuccess)
                    }
                }
                .buttonStyle(.plain)

            case .missed:
                VStack(spacing: 3) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.semanticError)
                    Text("Missed")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.semanticError)
                }

            case .skipped:
                VStack(spacing: 3) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.textSecondary)
                    Text("Skipped")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }

            case .pending:
                Button {
                    if currentTimeLabel != item.timeLabel {
                        showTimingConfirm = true
                    } else {
                        onMarkTaken()
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .stroke(Color.brandPrimary, lineWidth: 2.5)
                                .frame(width: 34, height: 34)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.brandPrimary.opacity(0.4))
                        }
                        Text("Take")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(minWidth: 52)
    }

    // MARK: - Computed helpers

    private var scheduledTimeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: item.scheduledAt)
    }

    private var labelColor: Color {
        switch item.effectiveStatus {
        case .missed:  return Color.semanticError
        case .taken:   return Color.textSecondary
        default:       return Color.brandPrimary
        }
    }

    private var iconBackground: Color {
        switch item.effectiveStatus {
        case .taken:  return Color.semanticSuccess.opacity(0.12)
        case .missed: return Color.semanticError.opacity(0.12)
        default:      return Color.brandPrimaryLight
        }
    }

    private var iconForeground: Color {
        switch item.effectiveStatus {
        case .taken:  return Color.semanticSuccess
        case .missed: return Color.semanticError
        default:      return Color.brandPrimary
        }
    }

    private var iconName: String {
        switch item.effectiveStatus {
        case .taken:  return "pills.fill"
        case .missed: return "pills"
        default:      return "pills.fill"
        }
    }
}

#Preview {
    VStack {
        DoseItemRow(item: .preview(status: .pending))
        DoseItemRow(item: .preview(status: .taken))
        DoseItemRow(item: .preview(status: .missed))
    }
    .background(Color.appSurface)
}

// MARK: - Preview helper
extension DoseDisplayItem {
    static func preview(status: DoseStatus) -> DoseDisplayItem {
        DoseDisplayItem(
            id: UUID(), medicationId: UUID(), scheduleId: UUID(),
            medicationName: "Lisinopril", dosageDisplay: "1 Tablet",
            medicationCategory: "Blood Pressure",
            usageNote: "Only take if you have pain",
            scheduledAt: .now, timeLabel: .morning,
            mealTiming: .before, status: status
        )
    }
}
