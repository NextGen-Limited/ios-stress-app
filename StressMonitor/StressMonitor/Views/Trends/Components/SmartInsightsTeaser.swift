import SwiftUI

/// Static "Coming Soon" teaser card for Smart Insights — matches Figma design
struct SmartInsightsTeaser: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Smart Insights")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Text("Personalized analysis based on your rhythm")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                Button(action: {}) {
                    Text("Coming Soon")
                        .font(Typography.caption1.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#FFD60A"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Cat mascot peeking from bottom-right corner
            Image("CharacterSleeping")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .offset(x: -8, y: 8)
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }
}

#Preview {
    SmartInsightsTeaser()
        .padding()
        .background(Color.backgroundLight)
}
