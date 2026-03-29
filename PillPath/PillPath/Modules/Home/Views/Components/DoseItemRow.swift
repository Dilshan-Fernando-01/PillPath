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
            HStack(spacing: AppSpacing.md) {

                // Pill icon
                pillIcon

                // Name + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.medicationName)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(labelColor)

                    Text(rowSubtitle)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Status control
                statusControl
            }

            // Usage note (e.g. "Only take if you have pain")
            if let note = item.usageNote, !note.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.semanticWarning)
                    Text(note)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticWarning)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 56) // align with text column
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
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
                .frame(width: 44, height: 44)
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundStyle(iconForeground)
        }
    }

    private var statusControl: some View {
        Group {
            switch item.effectiveStatus {
            case .taken:
                Button { showUndoConfirm = true } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.semanticSuccess)
                }
                .buttonStyle(.plain)

            case .missed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.semanticError)

            case .skipped:
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.textSecondary)

            case .pending:
                Button {
                    if currentTimeLabel != item.timeLabel {
                        showTimingConfirm = true
                    } else {
                        onMarkTaken()
                    }
                } label: {
                    Circle()
                        .stroke(Color.appBorder, lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed helpers

    private var rowSubtitle: String {
        var parts = [item.dosageDisplay]
        if let cat = item.medicationCategory, !cat.isEmpty {
            parts.append(cat)
        }
        return parts.joined(separator: " • ")
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
