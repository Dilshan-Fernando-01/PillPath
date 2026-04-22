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

    @State private var showUndoConfirm    = false
    @State private var showTimingConfirm  = false
    @State private var showLateConfirm    = false

    private var currentTimeLabel: DoseTimeLabel {
        DoseTimeLabel.from(hour: Calendar.current.component(.hour, from: .now))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(accentBarColor)
                .frame(width: 4)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 0) {

                // Status banner (active time / late)
                if item.effectiveStatus == .pending && !item.isLate && currentTimeLabel == item.timeLabel {
                    HStack(spacing: 5) {
                        Image(systemName: "bell.fill").font(.system(size: 10))
                        Text("Time to take this medication")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                }

                if item.isLate {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                        Text("Dose time has passed — scheduled \(scheduledTimeDisplay)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.semanticWarningText)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, 8)
                    .padding(.bottom, 2)
                }

                HStack(spacing: 12) {
                    pillIcon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.medicationName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(labelColor)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.textSecondary)
                            Text(scheduledTimeDisplay)
                                .font(.system(size: 12))
                                .foregroundStyle(item.isLate ? Color.semanticWarningText : Color.textSecondary)
                            if !item.dosageDisplay.isEmpty {
                                Text("·").foregroundStyle(Color.textSecondary.opacity(0.5))
                                Text(item.dosageDisplay)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }

                        if let cat = item.medicationCategory, !cat.isEmpty {
                            Text(cat)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textSecondary.opacity(0.6))
                        }
                    }

                    Spacer()
                    statusControl
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 12)

                if let note = item.usageNote, !note.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.semanticWarningText)
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.semanticWarningText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, AppSpacing.md)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(rowBackground)
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
        .confirmationDialog(
            "Dose time has passed",
            isPresented: $showLateConfirm,
            titleVisibility: .visible
        ) {
            Button("Take Anyway") { onMarkTaken() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(item.medicationName) was scheduled for \(scheduledTimeDisplay). You're taking it late. Are you sure you want to log this dose?")
        }
    }



    private var pillIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconBackground)
                .frame(width: 46, height: 46)
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconForeground)
        }
    }

    private var statusControl: some View {
        Group {
            switch item.effectiveStatus {
            case .taken:
                Button { showUndoConfirm = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Taken")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.semanticSuccess)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.semanticSuccess.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

            case .missed:
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Missed")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.semanticError)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.semanticError.opacity(0.1))
                .clipShape(Capsule())

            case .skipped:
                HStack(spacing: 5) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Skipped")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.textSecondary.opacity(0.1))
                .clipShape(Capsule())

            case .pending:
                Button {
                    if item.isLate {
                        showLateConfirm = true
                    } else if currentTimeLabel != item.timeLabel {
                        showTimingConfirm = true
                    } else {
                        onMarkTaken()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Take")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(pendingStrokeColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }



    private var pendingStrokeColor: Color {
        item.isLate ? Color.semanticWarningText : Color.brandPrimary
    }

    private var accentBarColor: Color {
        if item.isLate { return Color.semanticWarning }
        switch item.effectiveStatus {
        case .taken:   return Color.semanticSuccess
        case .missed:  return Color.semanticError
        case .skipped: return Color.textSecondary.opacity(0.4)
        case .pending: return currentTimeLabel == item.timeLabel ? Color.brandPrimary : Color.appBorder
        }
    }

    private var rowBackground: Color {
        if item.isLate { return Color.semanticWarning.opacity(0.06) }
        switch item.effectiveStatus {
        case .taken:  return Color.semanticSuccess.opacity(0.03)
        case .missed: return Color.semanticError.opacity(0.04)
        default:      return Color.clear
        }
    }

    private var scheduledTimeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: item.scheduledAt)
    }

    private var labelColor: Color {
        if item.isLate { return Color.semanticWarningText }
        switch item.effectiveStatus {
        case .missed:  return Color.semanticError
        case .taken:   return Color.textSecondary
        default:       return Color.brandPrimary
        }
    }

    private var iconBackground: Color {
        if item.isLate { return Color.semanticWarning.opacity(0.15) }
        switch item.effectiveStatus {
        case .taken:  return Color.semanticSuccess.opacity(0.12)
        case .missed: return Color.semanticError.opacity(0.12)
        default:      return Color.brandPrimaryLight
        }
    }

    private var iconForeground: Color {
        if item.isLate { return Color.semanticWarningText }
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
