import SwiftUI

/// Compact trust indicators shown beneath the plan grid on the paywall.
/// Three rows: rating + user count, iOS version target, and Family Sharing.
struct TrustRow: View {
    var body: some View {
        VStack(spacing: 10) {
            trustItem(icon: "star.fill", tint: Color.iapAmber, text: "4.8\u{2605} from 12K users")
            trustItem(icon: "iphone", tint: Color.iapHeaderTeal, text: "Designed for iOS 17")
            trustItem(icon: "house.fill", tint: Color.iapSavingsGreen, text: "Family Sharing enabled")
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.iapCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.iapIconBorder.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trusted by 12 thousand users. Designed for iOS 17. Family Sharing enabled.")
    }

    private func trustItem(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(text)
                .font(Typography.iapPlanFooter)
                .foregroundStyle(Color.iapTextSecondary)
            Spacer()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    TrustRow()
        .padding()
        .background(Color.iapWarmBackground)
}
