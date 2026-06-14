import SwiftUI

struct PremiumBannerView: View {
    var action: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Light blue gradient background
            LinearGradient(
                colors: [Color(hex: "#B8E4F0"), Color(hex: "#D4F1F9")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Cat mascot anchored bottom-left
            HStack(alignment: .bottom) {
                RippleCharacterView(mood: .celebrating, size: 110)

                Spacer()
            }

            // Text + CTA overlay centered
            VStack(spacing: 8) {
                Text("UNLOCK PREMIUM")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#1A6B8A"))

                Text("Unlimited Access to premium features")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)

                Button(action: action) {
                    Text("Upgrade Now")
                        .font(Typography.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#F39C12"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.leading, 110) // leave space for mascot
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }
}

#Preview {
    PremiumBannerView()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
