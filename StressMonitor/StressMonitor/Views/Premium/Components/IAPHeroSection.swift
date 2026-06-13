import SwiftUI

struct IAPHeroSection: View {
    var body: some View {
        VStack(spacing: 0) {
            // Orb illustration
            ZStack {
                // Spark badges
                sparkBadge(icon: "sparkles", color: Color(hex: "FFAE3B"), offsetX: 55, offsetY: -48)
                sparkBadge(icon: "checkmark", color: Color(hex: "4FC01B"), offsetX: -55, offsetY: 50)

                // Main orb
                RoundedRectangle(cornerRadius: 42)
                    .fill(
                        LinearGradient(
                            colors: [Color.iapGradientStart, Color.iapGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 126, height: 126)
                    .shadow(color: Color(hex: "24B9CC").opacity(0.28), radius: 24, y: 12)
                    .overlay {
                        // Person icon
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                    }
            }
            .frame(height: 140)

            // Headline
            Text("Less guessing.\nMore calm.")
                .font(Typography.iapHeroHeadline)
                .tracking(-0.055 * 32) // tight tracking
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.iapTextPrimary)
                .padding(.top, 4)
                .padding(.horizontal, 40)

            // Subtitle
            Text("Turn your Apple Watch signals into guided recovery plans, AI coaching, and stress patterns you can act on.")
                .font(Typography.iapHeroSubtitle)
                .foregroundStyle(Color.iapTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 40)
                .padding(.top, 10)

            // Promise pills
            HStack(spacing: 7) {
                promisePill(icon: "checkmark", text: "Private by design")
                promisePill(icon: nil, text: "Cancel anytime")
            }
            .padding(.top, 14)
        }
    }

    // MARK: - Subcomponents

    private func promisePill(icon: String?, text: String) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(Typography.iapPillLabel)
        }
        .foregroundStyle(Color.iapHeaderTeal)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.iapPillBackground)
                .overlay(Capsule().stroke(Color.iapIconBorder.opacity(0.15), lineWidth: 1))
        )
    }

    private func sparkBadge(icon: String, color: Color, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.iapCardBackground)
            .frame(width: 30, height: 30)
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            .offset(x: offsetX, y: offsetY)
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        IAPHeroSection()
            .padding(.top, 20)
    }
}
