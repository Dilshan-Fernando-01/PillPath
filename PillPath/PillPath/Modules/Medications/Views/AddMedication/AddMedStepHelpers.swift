
import SwiftUI


@ViewBuilder
func stepHeader(title: String, subtitle: String? = nil) -> some View {
    VStack(alignment: .leading, spacing: AppSpacing.xs) {
        Text(title)
            .font(AppFont.title())
            .foregroundStyle(Color.textPrimary)
        if let subtitle {
            Text(subtitle)
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}


struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .tracking(0.8)
    }
}


struct FieldCard<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFont.subheadline())
                .foregroundStyle(Color.textSecondary)
            content
        }
    }
}
