import SwiftUI

/// Smart Insights card with "Coming Soon" badge
/// Figma: White card with cat mascot and "Coming Soon" CTA
struct SmartInsightsCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Insights")
                    .font(.custom("Lato-Bold", size: 18))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                Text("Personalized analysis based on your rhythm")
                    .font(.custom("Lato-Regular", size: 14))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            Button(action: {
                // Coming soon action
            }) {
                Text("Coming Soon")
                    .font(.custom("Lato-Bold", size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#FFD700"))
                    .cornerRadius(8)
            }

            // Cat mascot placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "cat.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "#333333"))
                )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

#Preview("SmartInsightsCard") {
    SmartInsightsCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
