import SwiftUI

struct PremiumBannerView: View {
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            Text("UNLOCK PREMIUM")
                .font(Typography.headline)
                .foregroundColor(.white)

            Text("Unlock all features to premium features")
                .font(Typography.caption1)
                .foregroundColor(.white.opacity(0.8))

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade Now")
                        .font(Typography.subheadline.bold())
                }
                .foregroundColor(Color(hex: "#1A1A1A"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#F39C12"))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#5DADE2"))
        .cornerRadius(16)
    }
}

#Preview {
    PremiumBannerView()
        .padding()
}
