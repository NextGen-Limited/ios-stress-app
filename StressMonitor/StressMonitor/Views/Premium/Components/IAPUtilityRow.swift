import SwiftUI

// MARK: - Trust Indicators (3-column grid)

struct IAPTrustIndicators: View {
    var body: some View {
        HStack(spacing: 8) {
            trustItem(icon: "apple.logo", title: "Apple secure purchase")
            trustItem(icon: "arrow.triangle.2.circlepath", title: "Restore purchases")
            trustItem(icon: "xmark.circle", title: "Cancel anytime")
        }
    }

    private func trustItem(icon: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(Typography.iapTrustIcon)
                .foregroundStyle(Color.iapTextPrimary)

            Text(title)
                .font(Typography.iapTrustLabel)
                .foregroundStyle(Color.iapTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.iapTrustBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.iapIconBorder.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Footer Utility Links

struct IAPFooterLinks: View {
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button("Restore") { onRestore() }
                .foregroundStyle(Color.iapTextSecondary)

            Link("Manage subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .foregroundStyle(Color.iapTextSecondary)
        }
        .font(Typography.iapUtilityLabel)
    }
}

// MARK: - Legacy alias for backward compatibility
struct IAPUtilityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(Typography.iapUtilityLabel)
                    .foregroundStyle(Color.iapTextPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
