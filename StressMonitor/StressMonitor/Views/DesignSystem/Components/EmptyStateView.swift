import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(title)
                .font(Typography.title2)
                .fontWeight(.bold)

            Text(message)
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.primaryBlue)
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension EmptyStateView {
    init(
        systemImage icon: String,
        title: String,
        message: String
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = nil
        self.action = nil
    }

    static let noData = EmptyStateView(
        systemImage: "chart.bar",
        title: "No Measurements",
        message: "Take a measurement to see your data here"
    )

    static let noTrends = EmptyStateView(
        systemImage: "chart.xyaxis.slash",
        title: "Need More Data",
        message: "Continue measuring for 7 days to see trends"
    )
}
