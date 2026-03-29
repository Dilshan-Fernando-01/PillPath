//
//  EventFormView.swift
//  PillPath — Scheduling Module
//
//  Add / Edit a MedicalEvent.
//  Includes medication linking and local notification for upcoming events.
//

import SwiftUI
import UserNotifications

struct EventFormView: View {

    @ObservedObject var viewModel: ActivityViewModel
    var existingEvent: MedicalEvent? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var title           = ""
    @State private var provider        = ""
    @State private var date            = Date()
    @State private var type: MedicalEventType = .note
    @State private var notes           = ""
    @State private var selectedMedIds  = Set<UUID>()
    @State private var isSaving        = false
    @State private var validationError: String?

    private var isEditing: Bool { existingEvent != nil }
    private var allMeds: [Medication] {
        (viewModel.activeMedications + viewModel.stoppedMedications)
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {

                    formField(label: "Event Title", required: true) {
                        TextField("e.g. Annual checkup", text: $title)
                            .font(AppFont.body())
                    }

                    formField(label: "Provider / Doctor") {
                        TextField("e.g. Dr. Smith", text: $provider)
                            .font(AppFont.body())
                            .foregroundStyle(provider.isEmpty ? Color.textSecondary : Color.brandPrimary)
                    }

                    formField(label: "Event Type", required: true) {
                        Picker("Type", selection: $type) {
                            ForEach(MedicalEventType.allCases) { t in
                                Text(t.displayName).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    formField(label: "Date & Time", required: true) {
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .tint(Color.brandPrimary)
                    }

                    // Linked Medications
                    if !allMeds.isEmpty {
                        linkedMedicationsSection
                    }

                    formField(label: "Notes (optional)") {
                        TextEditor(text: $notes)
                            .font(AppFont.body())
                            .frame(minHeight: 80)
                            .foregroundStyle(Color.textPrimary)
                    }

                    if date > .now {
                        upcomingNoticeRow
                    }

                    if let err = validationError {
                        Text(err)
                            .font(AppFont.caption())
                            .foregroundStyle(Color.semanticError)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(
                        title: isSaving ? "Saving…" : (isEditing ? "Update Event" : "Save Event"),
                        isLoading: isSaving
                    ) { save() }
                    .padding(.top, AppSpacing.sm)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
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
        .onAppear {
            viewModel.loadMedications()
            prefill()
        }
    }

    // MARK: - Linked Medications

    private var linkedMedicationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 2) {
                Text("Linked Medications")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                Text("(optional)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(allMeds) { med in
                    Button {
                        if selectedMedIds.contains(med.id) {
                            selectedMedIds.remove(med.id)
                        } else {
                            selectedMedIds.insert(med.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedMedIds.contains(med.id)
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMedIds.contains(med.id)
                                                 ? Color.brandPrimary : Color.appBorder)
                            Text(med.name)
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(med.dosageDisplay)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                    }
                    .buttonStyle(.plain)

                    if med.id != allMeds.last?.id {
                        Divider().padding(.leading, AppSpacing.md)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Upcoming Notice

    private var upcomingNoticeRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.semanticWarning)
            Text("You'll be reminded 24 hours before this event.")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.semanticWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Form Field

    private func formField<Content: View>(
        label: String,
        required: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: 2) {
                Text(label)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                if required {
                    Text("*").font(AppFont.caption()).foregroundStyle(Color.semanticError)
                }
            }
            content()
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
        }
    }

    // MARK: - Logic

    private func prefill() {
        guard let ev = existingEvent else { return }
        title          = ev.title
        provider       = ev.provider ?? ""
        date           = ev.date
        type           = ev.type
        notes          = ev.notes ?? ""
        selectedMedIds = Set(ev.medicationIds)
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Title is required."
            return
        }
        validationError = nil
        isSaving = true

        let event = MedicalEvent(
            id: existingEvent?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty
                         ? nil : notes.trimmingCharacters(in: .whitespaces),
            provider: provider.trimmingCharacters(in: .whitespaces).isEmpty
                      ? nil : provider.trimmingCharacters(in: .whitespaces),
            medicationIds: Array(selectedMedIds),
            date: date,
            type: type,
            createdAt: existingEvent?.createdAt ?? .now
        )

        viewModel.saveEvent(event)
        scheduleNotificationIfNeeded(for: event)
        isSaving = false
        dismiss()
    }

    private func scheduleNotificationIfNeeded(for event: MedicalEvent) {
        guard event.date > .now else { return }
        let fireDate = event.date.addingTimeInterval(-24 * 3600)
        guard fireDate > .now else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Upcoming: \(event.title)"
        content.body      = (event.provider.map { "with \($0) • " } ?? "")
                          + DateFormatter.localizedString(from: event.date, dateStyle: .medium, timeStyle: .short)
        content.sound     = .default

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["event_\(event.id.uuidString)"])
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
