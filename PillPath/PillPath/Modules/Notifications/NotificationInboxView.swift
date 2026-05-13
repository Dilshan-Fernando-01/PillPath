
import SwiftUI

struct NotificationInboxView: View {

    @ObservedObject var viewModel: NotificationBellViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.notifications.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasUnread {
                        Button("Mark All Read") { viewModel.markAllRead() }
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
            }
        }
    }

    private var notificationList: some View {
        List {
            ForEach(viewModel.notifications) { notif in
                NotificationRow(notification: notif)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.markRead(notif.id) }
                    .listRowBackground(
                        notif.isRead
                            ? Color.appBackground
                            : Color.brandPrimary.opacity(0.06)
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .onDelete { viewModel.delete(at: $0) }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.textSecondary.opacity(0.35))
            Text("No Notifications")
                .font(AppFont.headline())
                .foregroundStyle(Color.textPrimary)
            Text("You're all caught up.")
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
        }
    }
}

private struct NotificationRow: View {
    let notification: InAppNotification

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {

            ZStack {
                Circle()
                    .fill(notification.type.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(notification.type.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: notification.isRead ? .regular : .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text(notification.createdAt.relativeTimeDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }
                Text(notification.body)
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(notification.type.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(notification.type.accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(notification.type.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
