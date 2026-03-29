//
//  EventDetailView.swift
//  PillPath — Scheduling Module
//
//  Full-screen detail for a single MedicalEvent.
//  Provider name shown in brand blue. Edit / Delete actions.
//

import SwiftUI

struct EventDetailView: View {

    let event: MedicalEvent
    @ObservedObject var viewModel: ActivityViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEditForm  = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {

                    // Header card
                    headerCard

                    // Details card
                    detailsCard

                    // Notes
                    if let desc = event.notes, !desc.isEmpty {
                        notesCard(desc)
                    }

                    // Linked Medications
                    if !linkedMedications.isEmpty {
                        linkedMedicationsCard
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditForm = true
                        } label: {
                            Label("Edit Event", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Event", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditForm, onDismiss: { viewModel.loadEvents(); dismiss() }) {
            EventFormView(viewModel: viewModel, existingEvent: event)
        }
        .confirmationDialog(
            "Delete \"\(event.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteEvent(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This event will be permanently removed.")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(typeColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: typeIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                Text(event.type.displayName)
                    .font(AppFont.caption())
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(typeColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            if event.date > .now {
                VStack(spacing: 2) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.semanticWarning)
                    Text("Upcoming")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticWarning)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: "calendar", label: "Date", value: formattedDate)
            Divider().padding(.leading, 52)
            detailRow(icon: "clock", label: "Time", value: formattedTime)
            if let provider = event.provider, !provider.isEmpty {
                Divider().padding(.leading, 52)
                providerRow(provider: provider)
            }
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                Text(value)
                    .font(AppFont.body())
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func providerRow(provider: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Provider / Doctor")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                Text(provider)
                    .font(AppFont.body())
                    .foregroundStyle(Color.brandPrimary)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Linked Medications

    private var linkedMedications: [Medication] {
        let all = viewModel.activeMedications + viewModel.stoppedMedications
        return all.filter { event.medicationIds.contains($0.id) }
    }

    private var linkedMedicationsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandPrimary)
                Text("Linked Medications")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(spacing: 0) {
                ForEach(linkedMedications) { med in
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimaryLight)
                                .frame(width: 36, height: 36)
                            Image(systemName: med.form.systemIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.brandPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(AppFont.body())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)
                            Text(med.dosageDisplay)
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        if !med.isActive {
                            Text("Stopped")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appBorder.opacity(0.5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)

                    if med.id != linkedMedications.last?.id {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }

    // MARK: - Notes Card

    private func notesCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandPrimary)
                Text("Notes")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
            }
            Text(text)
                .font(AppFont.body())
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f.string(from: event.date)
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: event.date)
    }

    private var typeIcon: String {
        switch event.type {
        case .doctorVisit: return "stethoscope"
        case .test:        return "testtube.2"
        case .note:        return "note.text"
        case .other:       return "calendar"
        }
    }

    private var typeColor: Color {
        switch event.type {
        case .doctorVisit: return Color.brandPrimary
        case .test:        return Color.semanticInfo
        case .note:        return Color.semanticWarning
        case .other:       return Color.textSecondary
        }
    }
}
