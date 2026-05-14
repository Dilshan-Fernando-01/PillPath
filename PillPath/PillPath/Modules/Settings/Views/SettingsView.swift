
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var backupVM = BackupViewModel()
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var contactName   = ""
    @State private var contactPhone  = ""
    @State private var showSavedBanner = false
    @State private var showSignOutModal = false
    @State private var showClearCalendarConfirm = false
    @State private var clearedEventCount: Int? = nil

    private var resolvedColorScheme: ColorScheme? {
        if let explicit = settings.colorScheme.colorScheme { return explicit }
        let style = UIScreen.main.traitCollection.userInterfaceStyle
        return style == .dark ? .dark : .light
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {

                        securitySection
                        cloudBackupSection
                        notificationsSection
                        emergencyContactSection
                        accessibilitySection
                        appearanceSection
                        calendarSection
                        generalSection

                        Button {
                            showSignOutModal = true
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(AppFont.body()).fontWeight(.semibold)
                            }
                            .foregroundStyle(Color.semanticError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(Color.semanticError.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppSpacing.md)

            
                        PrimaryButton(title: "Save Settings") {
                            saveEmergencyContact()
                            withAnimation { showSavedBanner = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showSavedBanner = false }
                                dismiss()
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.md)
                }

            
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
        .preferredColorScheme(resolvedColorScheme)
        .environment(\.legibilityWeight, settings.highContrastMode ? .bold : nil)
        .tint(settings.highContrastMode ? Color(hex: "#1A3FB8") : Color.brandPrimary)
        .onAppear { prefillContact() }
        .appModal(
            isPresented: $showSignOutModal,
            icon: .signOut,
            title: "Sign Out",
            message: "Are you sure you want to sign out? You'll need to sign in again to access your medications.",
            primaryButton: .destructive("Sign Out") {
                authViewModel.signOut()
                dismiss()
            },
            secondaryButton: .cancel()
        )
    }

   

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

    private var cloudBackupSection: some View {
        settingsSection(title: "CLOUD BACKUP", trailingIcon: "icloud.fill", trailingIconColor: Color.brandPrimary) {
            VStack(spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Backup")
                            .font(AppFont.body())
                            .foregroundStyle(Color.textPrimary)
                        if let date = backupVM.lastBackupDate {
                            Text(date.formatted(.dateTime.day().month().year().hour().minute()))
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                        } else {
                            Text("Never backed up")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    Spacer()
                    if case .loading = backupVM.state {
                        ProgressView()
                            .tint(Color.brandPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)

                Divider().padding(.leading, AppSpacing.md)

                Button {
                    Task { await backupVM.backup() }
                } label: {
                    HStack {
                        Text("Back Up Now")
                            .font(AppFont.body())
                            .foregroundStyle(Color.brandPrimary)
                        Spacer()
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)
                .disabled(backupVM.state == .loading)

                Divider().padding(.leading, AppSpacing.md)

                Button {
                    backupVM.showRestoreConfirm = true
                } label: {
                    HStack {
                        Text("Restore from Cloud")
                            .font(AppFont.body())
                            .foregroundStyle(Color.semanticWarning)
                        Spacer()
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.semanticWarning)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)
                .disabled(backupVM.state == .loading)
            }
        }
        .task { await backupVM.checkCloudBackup() }
        .onChange(of: backupVM.state) { _, newState in
            switch newState {
            case .success:
                withAnimation { showSavedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSavedBanner = false }
                    backupVM.dismissState()
                }
            case .failure(let msg):
                backupVM.errorMessage = msg
                backupVM.dismissState()
            default:
                break
            }
        }
        .alert("Backup Error", isPresented: Binding(
            get: { backupVM.errorMessage != nil },
            set: { if !$0 { backupVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { backupVM.errorMessage = nil }
        } message: {
            Text(backupVM.errorMessage ?? "")
        }
        .appModal(
            isPresented: $backupVM.showRestoreConfirm,
            icon: .warning,
            title: "Restore from Cloud",
            message: backupVM.hasLocalData
                ? "You currently have \(backupVM.localMedicationCount) medication(s) saved locally. Restoring will replace all of them with the cloud backup. This cannot be undone."
                : "This will restore your medications, schedules, and events from the cloud backup.",
            primaryButton: .destructive("Replace & Restore") {
                Task { await backupVM.restore() }
            },
            secondaryButton: .cancel()
        )
    }

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

   

    private var emergencyContactSection: some View {
        settingsSection(
            title: "EMERGENCY CONTACT",
            trailingIcon: "diamond.fill",
            trailingIconColor: Color.semanticError
        ) {
            VStack(spacing: AppSpacing.sm) {
            
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


    private var calendarSection: some View {
        settingsSection(title: "CALENDAR SYNC", trailingIcon: "calendar", trailingIconColor: Color.brandPrimary) {
            Button {
                showClearCalendarConfirm = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear PillPath Calendar Events")
                            .font(AppFont.body())
                            .foregroundStyle(Color.semanticError)
                        Text("Remove all medication & event entries synced to Apple Calendar")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.semanticError)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog(
            "Clear all PillPath calendar events?",
            isPresented: $showClearCalendarConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                let removed = EventKitService.shared.removeAllPillPathEvents()
                clearedEventCount = removed
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes only events synced by PillPath. Your other calendar events are untouched.")
        }
        .alert("Calendar Cleared", isPresented: Binding(
            get: { clearedEventCount != nil },
            set: { if !$0 { clearedEventCount = nil } }
        )) {
            Button("OK", role: .cancel) { clearedEventCount = nil }
        } message: {
            Text("Removed \(clearedEventCount ?? 0) event(s) from your calendar.")
        }
    }

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

    

    private var accessibilitySection: some View {
        settingsSection(title: "ACCESSIBILITY") {
            VStack(spacing: 0) {
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

    

    private var generalSection: some View {
        settingsSection(title: "GENERAL") {
            VStack(spacing: 0) {
                HStack {
                    Text("Language")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("English")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textSecondary)
                    Text("Coming Soon")
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brandPrimaryLight)
                        .clipShape(Capsule())
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
                .opacity(0.7)

                Divider().padding(.leading, AppSpacing.md)

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

  
    private func prefillContact() {
        contactName  = settings.emergencyContact?.name ?? ""
        contactPhone = settings.emergencyContact?.phoneNumber ?? ""
    }

    private func saveEmergencyContact() {
        let name  = contactName.trimmingCharacters(in: .whitespaces)
        let phone = contactPhone.trimmingCharacters(in: .whitespaces)
        if name.isEmpty && phone.isEmpty {
            settings.emergencyContact = nil
        } else {
            settings.emergencyContact = EmergencyContact(name: name, phoneNumber: phone)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(AuthViewModel())
}
