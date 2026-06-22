import SwiftUI

/// Compact premium upsell pill: gold-tinted "Plus" label with a "Try free ›" call to action.
///
/// Tap triggers the supplied `onTap` (typically pushing `IAPPremiumView`).
struct PlusPill: View {
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            HapticManager.shared.buttonPress()
            onTap?()
        } label: {
            HStack(spacing: 6) {
                Text("Plus")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.premiumGold)

                Text("Try free ›")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.premiumGold.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.premiumGold.opacity(0.14))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.premiumGold.opacity(0.32), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plus. Try free.")
    }
}

#Preview {
    PlusPill()
        .padding()
        .background(Color.appBackground)
}
