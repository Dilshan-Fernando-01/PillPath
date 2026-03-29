//
//  AddMedStep7AdvancedView.swift
//  PillPath — Medications Module
//
//  Step 7: Advanced options — dates, reminders, event, photo, display name, inventory.
//

import SwiftUI
import PhotosUI

struct AddMedStep7AdvancedView: View {

    @ObservedObject var viewModel: AddMedicationViewModel
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "Advanced Options",
                subtitle: "All fields are optional — fill in as needed."
            )

            // Dates section
            datesSection

            // Reminders section
            remindersSection

            // Medical event link
            eventSection

            // Photo
            photoSection

            // Display name
            displayNameSection

            // Notes
            notesSection

            // Inventory
            inventorySection

            Spacer()
        }
    }

    // MARK: - Dates

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Duration")

            Toggle(isOn: $viewModel.isOngoing.animation()) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "infinity")
                        .foregroundStyle(Color.brandPrimary)
                    Text("Ongoing (no end date)")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .tint(Color.brandPrimary)
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            HStack(spacing: AppSpacing.sm) {
                dateField(label: "Start", date: $viewModel.startDate, range: Date.distantPast...Date.distantFuture)

                if !viewModel.isOngoing {
                    dateField(label: "End", date: $viewModel.endDate, range: viewModel.startDate...Date.distantFuture)
                }
            }
        }
    }

    private func dateField(label: String, date: Binding<Date>, range: ClosedRange<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
            DatePicker("", selection: date, in: range, displayedComponents: .date)
                .labelsHidden()
                .tint(Color.brandPrimary)
                .padding(AppSpacing.sm)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Reminders")

            Toggle(isOn: $viewModel.doseReminders.animation()) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.brandPrimary)
                    Text("Dose reminders")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .tint(Color.brandPrimary)
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            if viewModel.doseReminders {
                HStack {
                    Text("Notify me")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Picker("Offset", selection: $viewModel.notificationOffset) {
                        ForEach(NotificationOffset.allCases) { offset in
                            Text(offset.displayName).tag(offset)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.brandPrimary)
                }
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    // MARK: - Event

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Link to Medical Event (optional)")

            if viewModel.availableEvents.isEmpty {
                Text("No events yet. Add events from the Activity tab.")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            } else {
                Menu {
                    Button("None") { viewModel.selectedEventId = nil }
                    ForEach(viewModel.availableEvents) { event in
                        Button(event.title) { viewModel.selectedEventId = event.id }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(Color.brandPrimary)
                        Text(selectedEventTitle)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
            }
        }
        .onAppear { viewModel.loadEvents() }
    }

    private var selectedEventTitle: String {
        guard let id = viewModel.selectedEventId,
              let event = viewModel.availableEvents.first(where: { $0.id == id })
        else { return "Select event…" }
        return event.title
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Medication Photo (optional)")

            PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(Color.brandPrimaryLight)
                            .frame(width: 52, height: 52)
                        if let urlString = viewModel.photoURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "photo")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        } else {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(Color.brandPrimary)
                                .font(.system(size: 20))
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.photoURL == nil ? "Add Photo" : "Change Photo")
                            .font(AppFont.subheadline())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandPrimary)
                        Text("Helps identify your medication quickly")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    // Store as a local identifier — in production replace with file save
                    if let item = newItem {
                        viewModel.photoURL = item.itemIdentifier
                    }
                }
            }
        }
    }

    // MARK: - Display Name

    private var displayNameSection: some View {
        FieldCard(label: "Display Name (optional)") {
            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 20)
                TextField("e.g. Red pill for heart", text: $viewModel.displayName)
                    .font(AppFont.body())
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        FieldCard(label: "Notes (optional)") {
            TextField("Any additional notes…", text: $viewModel.notes, axis: .vertical)
                .font(AppFont.body())
                .lineLimit(3...6)
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Inventory

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Inventory Tracking")

            HStack(spacing: AppSpacing.sm) {
                // Current quantity
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Qty")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                    TextField("0", text: $viewModel.currentQuantity)
                        .keyboardType(.numberPad)
                        .font(AppFont.body())
                        .padding(AppSpacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }

                // Low threshold
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alert Below")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                    TextField("5", text: $viewModel.lowQuantityThreshold)
                        .keyboardType(.numberPad)
                        .font(AppFont.body())
                        .padding(AppSpacing.md)
                        .background(viewModel.lowQuantityAlert ? Color.appSurface : Color.appSurface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                        .disabled(!viewModel.lowQuantityAlert)
                }
            }

            Toggle(isOn: $viewModel.lowQuantityAlert) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.semanticWarning)
                    Text("Low quantity alert")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .tint(Color.brandPrimary)
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }
}
