import SwiftUI

/// Smart Insights card with "Coming Soon" badge
/// Figma: White card with cat mascot and "Coming Soon" CTA
struct SmartInsightsCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Insights")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text("Personalized analysis based on your rhythm")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            Button(action: {
                // Coming soon action
            }) {
                Text("Coming Soon")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#FFD700"))
                    .cornerRadius(8)
            }

            // Ripple water-droplet mascot
            RippleCharacterView(mood: .happy, size: 56)
        }
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

#Preview("SmartInsightsCard") {
    SmartInsightsCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
