
import SwiftUI


struct AppModal: View {


    let icon: AppModalIcon
    let title: String
    let message: String
    let primaryButton: ModalButton
    var secondaryButton: ModalButton? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Color.appBorder)
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)

            ZStack {
                Circle()
                    .fill(icon.backgroundColor)
                    .frame(width: 72, height: 72)
                Group {
                    switch icon {
                    case .system(let name, _, let fg):
                        Image(systemName: name)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(fg)
                    case .emoji(let char):
                        Text(char)
                            .font(.system(size: 36))
                    }
                }
            }
            .padding(.bottom, AppSpacing.lg)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, AppSpacing.sm)

            Text(message)
                .font(AppFont.subheadline())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)

            HStack(spacing: AppSpacing.md) {
                if let secondary = secondaryButton {
                    ModalOutlineButton(label: secondary.label) {
                        secondary.action()
                        dismiss()
                    }
                }
                ModalFilledButton(
                    label: primaryButton.label,
                    color: primaryButton.color
                ) {
                    primaryButton.action()
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}


enum AppModalIcon {
    case system(_ name: String, background: Color, foreground: Color)
    case emoji(_ char: String)

    var backgroundColor: Color {
        switch self {
        case .system(_, let bg, _): return bg
        case .emoji: return Color.brandPrimaryLight
        }
    }

    static let warning = AppModalIcon.system(
        "exclamationmark.triangle.fill",
        background: Color.semanticWarning.opacity(0.15),
        foreground: Color.semanticWarning
    )
    static let destructive = AppModalIcon.system(
        "trash.fill",
        background: Color.semanticError.opacity(0.12),
        foreground: Color.semanticError
    )
    static let signOut = AppModalIcon.system(
        "rectangle.portrait.and.arrow.right",
        background: Color.semanticError.opacity(0.12),
        foreground: Color.semanticError
    )
    static let success = AppModalIcon.system(
        "checkmark.circle.fill",
        background: Color.semanticSuccess.opacity(0.12),
        foreground: Color.semanticSuccess
    )
    static let info = AppModalIcon.system(
        "info.circle.fill",
        background: Color.brandPrimaryLight,
        foreground: Color.brandPrimary
    )
}

struct ModalButton {
    let label: String
    let color: Color
    let action: () -> Void

    static func cancel(_ action: @escaping () -> Void = {}) -> ModalButton {
        ModalButton(label: "Cancel", color: Color.textSecondary, action: action)
    }
    static func destructive(_ label: String, action: @escaping () -> Void) -> ModalButton {
        ModalButton(label: label, color: Color.semanticError, action: action)
    }
    static func primary(_ label: String, action: @escaping () -> Void) -> ModalButton {
        ModalButton(label: label, color: Color.brandPrimary, action: action)
    }
}


private struct ModalFilledButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.headline())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ModalOutlineButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.headline())
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.appBorder, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}


extension View {
    func appModal(
        isPresented: Binding<Bool>,
        icon: AppModalIcon,
        title: String,
        message: String,
        primaryButton: ModalButton,
        secondaryButton: ModalButton? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            AppModal(
                icon: icon,
                title: title,
                message: message,
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(24)
        }
    }
}
