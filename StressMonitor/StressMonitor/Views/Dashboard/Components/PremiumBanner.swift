import SwiftUI

/// Premium upgrade banner with frosted glass gradient and cat mascot placeholder.
/// Refined to match the 04-home spec: soft blue gradient card, centered copy,
/// gold CTA button, and a right-side mascot cutout zone.
///
/// Spec reference: design/screens/04-home.html — `.premium-banner`.
struct PremiumBanner: View {
    var onUpgrade: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Frosted glass gradient background
            LinearGradient(
                colors: [
                    Color(hex: "E3F2FD"),
                    Color(hex: "BBDEFB"),
                    Color(hex: "90CAF9").opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 100, height: 100)
                .offset(x: 130, y: -50)

            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 1)
                .frame(width: 60, height: 60)
                .offset(x: -120, y: 45)

            HStack(spacing: 14) {
                // Left: copy
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "0288D1"))

                        Text("UNLOCK PREMIUM")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: "0277BD"))
                            .tracking(-0.36)
                    }

                    Text("Unlimited access to all\ncreatures & insights")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "01579B").opacity(0.82))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // CTA button
                    Button(action: { onUpgrade?() }) {
                        HStack(spacing: 4) {
                            Text("Upgrade Now")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFC107")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "FFC107").opacity(0.35), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)

                // Right: mascot zone (decorative placeholder)
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 64, height: 64)
                    Image(systemName: AppIconSystem.System.premium.sfSymbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
            }
            .padding(18)
        }
        .frame(height: 132)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock Premium. Unlimited access to all creatures and insights.")
        .accessibilityHint("Double tap to upgrade")
    }
}

#Preview("PremiumBanner") {
    PremiumBanner()
        .padding()
        .background(HomeCharacterDesignTokens.homeBackground)
}
