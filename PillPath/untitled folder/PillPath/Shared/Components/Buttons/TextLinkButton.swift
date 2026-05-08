
import SwiftUI

struct TextLinkButton: View {

    let title: String
    var color: Color = .textSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.subheadline())
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }
}

#Preview {
    VStack {
        TextLinkButton(title: "Skip for now") { }
        TextLinkButton(title: "Cancel", color: .semanticError) { }
    }
    .padding()
}
