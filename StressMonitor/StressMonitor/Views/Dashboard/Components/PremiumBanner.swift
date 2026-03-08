import SwiftUI

/// Premium upgrade banner with cat mascot illustration
/// Figma: Light blue banner with "UNLOCK PREMIUM" title and "Upgrade Now" button
struct PremiumBanner: View {
    var body: some View {
        ZStack(alignment: .top) {
            // Background with illustration
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#87CEEB"))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

            // Content
            VStack(spacing: 8) {
                Text("UNLOCK PREMIUM")
                    .font(.custom("Lato-Bold", size: 24))
                    .foregroundStyle(Color(hex: "#4682B4"))
                    .tracking(-0.48)

                Text("Unlimited Access to premium features")
                    .font(.custom("Lato-Regular", size: 14))
                    .foregroundStyle(Color(hex: "#6A5ACD"))

                // Upgrade button
                Button(action: {
                    // Premium upgrade action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)

                        Text("Upgrade Now")
                            .font(.custom("Lato-Bold", size: 16))
                            .foregroundStyle(.white)

                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), Color(hex: "#FFC107")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity)

            // Cat mascot placeholder (would be replaced with actual asset)
            // In Figma, there's a cat illustration on the right side
        }
        .frame(height: 180)
    }
}

#Preview("PremiumBanner") {
    PremiumBanner()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
