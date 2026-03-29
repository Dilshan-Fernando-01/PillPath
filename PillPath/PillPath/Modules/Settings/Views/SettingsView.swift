//
//  SettingsView.swift
//  PillPath — Settings Module
//
//  Matches Figma: Security → Notifications → Emergency Contact →
//    Accessibility → General → Save Settings
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.openURL) private var openURL

    // Local editable copies of emergency contact
    @State private var contactName   = ""
    @State private var contactPhone  = ""
    // Local editable copies of guardian contact
    @State private var guardianName    = ""
    @State private var guardianPhone   = ""
    @State private var guardianNotifyMedTaken  = true
    @State private var guardianNotifyMedMissed = true
    @State private var guardianNotifyEvents    = true
    @State private var showSavedBanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {

                        securitySection
                        notificationsSection
                        emergencyContactSection
                        guardianSection
                        accessibilitySection
                        appearanceSection
                        generalSection

                        // Save button
                        PrimaryButton(title: "Save Settings") {
                            saveEmergencyContact()
                            withAnimation { showSavedBanner = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSavedBanner = false }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.md)
                }

                // Saved banner
                if showSavedBanner {
                    VStack {
                        Spacer()
                        Text("Settings saved")
                            .font(AppFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.semanticSuccess)
                            .clipShape(Capsule())
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { prefillContact() }
    }

    // MARK: - Security

    private var securitySection: some View {
        settingsSection(title: "SECURITY") {
            VStack(spacing: 0) {
                settingsToggleRow(
                    title: "Enable Face ID / Touch ID Lock",
                    subtitle: "Secure the app using biometric authentication",
                    isOn: $settings.biometricLockEnabled
                )
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        settingsSection(title: "NOTIFICATIONS") {
            VStack(spacing: 0) {
                settingsToggleRow(
                    title: "Medication Reminders",
                    subtitle: nil,
                    isOn: $settings.medicationReminders
                )
                Divider().padding(.leading, AppSpacing.md)

                settingsToggleRow(
                    title: "Event Reminders",
                    subtitle: nil,
                    isOn: $settings.eventReminders
                )
                Divider().padding(.leading, AppSpacing.md)

                // Reminder Sound picker row
                Menu {
                    ForEach(ReminderSound.allCases) { sound in
                        Button {
                            settings.reminderSound = sound
                        } label: {
                            HStack {
                                Text(sound.displayName)
                                if settings.reminderSound == sound {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder Sound")
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                        }
                        Spacer()
                        Text(settings.reminderSound.displayName)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Emergency Contact

    private var emergencyContactSection: some View {
        settingsSection(
            title: "EMERGENCY CONTACT",
            trailingIcon: "diamond.fill",
            trailingIconColor: Color.semanticError
        ) {
            VStack(spacing: AppSpacing.sm) {
                // Contact Name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Contact Name")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                    TextField("", text: $contactName)
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                        .padding(AppSpacing.md)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .padding(.horizontal, AppSpacing.md)
                }

                // Phone Number
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Phone Number")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                    TextField("", text: $contactPhone)
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                        .keyboardType(.phonePad)
                        .padding(AppSpacing.md)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .padding(.horizontal, AppSpacing.md)
                }

                // Call button
                if !contactPhone.isEmpty {
                    Button {
                        let digits = contactPhone.filter(\.isNumber)
                        if let url = URL(string: "tel://\(digits)") {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 16))
                            Text("Call Emergency Contact")
                                .font(AppFont.body())
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.semanticError)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.md)
                }

                Spacer().frame(height: AppSpacing.sm)
            }
        }
    }

    // MARK: - Guardian

    private var guardianSection: some View {
        settingsSection(
            title: "GUARDIAN",
            trailingIcon: "shield.fill",
            trailingIconColor: Color.brandPrimary
        ) {
            VStack(spacing: AppSpacing.sm) {
                // Guardian Name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Guardian Name")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                    TextField("e.g. Jane Smith", text: $guardianName)
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                        .padding(AppSpacing.md)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .padding(.horizontal, AppSpacing.md)
                }

                // Guardian Phone
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Phone Number")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                    TextField("e.g. 0771234567", text: $guardianPhone)
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                        .keyboardType(.phonePad)
                        .padding(AppSpacing.md)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .padding(.horizontal, AppSpacing.md)
                }

                if !guardianName.isEmpty || !guardianPhone.isEmpty {
                    VStack(spacing: 0) {
                        settingsToggleRow(
                            title: "Notify when medication taken",
                            subtitle: nil,
                            isOn: $guardianNotifyMedTaken
                        )
                        Divider().padding(.leading, AppSpacing.md)
                        settingsToggleRow(
                            title: "Notify when medication missed",
                            subtitle: nil,
                            isOn: $guardianNotifyMedMissed
                        )
                        Divider().padding(.leading, AppSpacing.md)
                        settingsToggleRow(
                            title: "Notify on event reminders",
                            subtitle: nil,
                            isOn: $guardianNotifyEvents
                        )
                    }
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .padding(.horizontal, AppSpacing.md)
                }

                Spacer().frame(height: AppSpacing.sm)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        settingsSection(title: "APPEARANCE") {
            VStack(spacing: 0) {
                Menu {
                    ForEach(AppColorScheme.allCases) { scheme in
                        Button {
                            settings.colorScheme = scheme
                        } label: {
                            HStack {
                                Text(scheme.displayName)
                                if settings.colorScheme == scheme {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                        }
                        Spacer()
                        Text(settings.colorScheme.displayName)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        settingsSection(title: "ACCESSIBILITY") {
            VStack(spacing: 0) {
                // Text Size
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Text Size")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)

                    HStack(spacing: 0) {
                        ForEach(AppTextSize.allCases) { size in
                            Button {
                                settings.textSize = size
                            } label: {
                                Text(size.displayName)
                                    .font(.system(
                                        size: size == .small ? 13 : size == .medium ? 15 : 17,
                                        weight: settings.textSize == size ? .semibold : .regular
                                    ))
                                    .foregroundStyle(settings.textSize == size ? Color.brandPrimary : Color.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
                }

                Divider().padding(.leading, AppSpacing.md)

                settingsToggleRow(
                    title: "High Contrast Mode",
                    subtitle: nil,
                    isOn: $settings.highContrastMode
                )
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        settingsSection(title: "GENERAL") {
            VStack(spacing: 0) {
                // Language
                Menu {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            settings.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                if settings.language == lang {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Language")
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text(settings.language.displayName)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, AppSpacing.md)

                // About App
                HStack {
                    Text("About App")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("v\(settings.appVersion)")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textSecondary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    // MARK: - Reusable Components

    private func settingsSection<Content: View>(
        title: String,
        trailingIcon: String? = nil,
        trailingIconColor: Color = Color.textSecondary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.label())
                    .foregroundStyle(Color.textSecondary)
                    .kerning(0.5)
                if let icon = trailingIcon {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(trailingIconColor)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private func settingsToggleRow(
        title: String,
        subtitle: String?,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.body())
                    .foregroundStyle(Color.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.brandPrimary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Helpers

    private func prefillContact() {
        contactName  = settings.emergencyContact?.name ?? ""
        contactPhone = settings.emergencyContact?.phoneNumber ?? ""
        guardianName              = settings.guardianContact?.name ?? ""
        guardianPhone             = settings.guardianContact?.phoneNumber ?? ""
        guardianNotifyMedTaken    = settings.guardianContact?.notifyOnMedTaken  ?? true
        guardianNotifyMedMissed   = settings.guardianContact?.notifyOnMedMissed ?? true
        guardianNotifyEvents      = settings.guardianContact?.notifyOnEvents    ?? true
    }

    private func saveEmergencyContact() {
        let name  = contactName.trimmingCharacters(in: .whitespaces)
        let phone = contactPhone.trimmingCharacters(in: .whitespaces)
        if name.isEmpty && phone.isEmpty {
            settings.emergencyContact = nil
        } else {
            settings.emergencyContact = EmergencyContact(name: name, phoneNumber: phone)
        }

        let gName  = guardianName.trimmingCharacters(in: .whitespaces)
        let gPhone = guardianPhone.trimmingCharacters(in: .whitespaces)
        if gName.isEmpty && gPhone.isEmpty {
            settings.guardianContact = nil
        } else {
            settings.guardianContact = GuardianContact(
                name: gName,
                phoneNumber: gPhone,
                notifyOnMedTaken: guardianNotifyMedTaken,
                notifyOnMedMissed: guardianNotifyMedMissed,
                notifyOnEvents: guardianNotifyEvents
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}
