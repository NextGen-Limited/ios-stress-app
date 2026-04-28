import SwiftUI

struct IAPHeroSection: View {
    var body: some View {
        VStack(spacing: 20) {
            // Placeholder illustration (replace with Figma export later)
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.iapGradientStart, Color.iapGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
            }
            .frame(height: 120)

            // Tagline
            Text("CARE FOR YOUR\nMENTAL BALANCE")
                .font(Typography.iapTagline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.iapGradientStart, Color.iapGradientEnd],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .tracking(-0.32)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        IAPHeroSection()
            .padding(.top, 60)
    }
    .frame(height: 300)
}
