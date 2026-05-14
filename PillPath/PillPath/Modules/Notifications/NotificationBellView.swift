
import SwiftUI

struct NotificationBellView: View {

    @ObservedObject var viewModel: NotificationBellViewModel

    var body: some View {
        Button {
            viewModel.showInbox = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.brandPrimaryLight)
                    .frame(width: 42, height: 42)
                Image(systemName: viewModel.hasUnread ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.brandPrimary)
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.semanticError)
                            .frame(width: 18, height: 18)
                        Text(viewModel.unreadCount > 9 ? "9+" : "\(viewModel.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $viewModel.showInbox, onDismiss: { viewModel.load() }) {
            NotificationInboxView(viewModel: viewModel)
        }
    }
}
