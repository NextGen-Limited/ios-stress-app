import SwiftUI

/// Widget placeholder for watch complications and data sharing options
struct ComplicationWidget: View {
    let title: String
    let icon: String?
    let tier: StressTier?

    init(title: String, icon: String? = nil, tier: StressTier? = nil) {
        self.title = title
        self.icon = icon
        self.tier = tier
    }

    var body: some View {
        VStack(spacing: 6) {
            // Widget preview (85x44)
            ZStack {
                RoundedRectangle(cornerRadius: 10.9)
                    .fill(previewFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.9)
                            .stroke(Color.settingsCardBorder, lineWidth: 0.91)
                    )

                VStack(spacing: 4) {
                    if let tier {
                        RippleMoodFace(tier: tier, size: 28, showsRing: true, glow: false)

                        Text("Ripple")
                            .font(.system(size: 7.5, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.system(size: 12))
                            .foregroundColor(.settingsRippleBlue)

                        skeletonBars
                    } else {
                        RippleMoodFace(tier: .calm, size: 28, showsRing: true, glow: false)
                        skeletonBars
                    }
                }
            }
            .frame(width: 85.6, height: 43.7)

            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
        }
        .frame(width: 147.5, height: 112.9)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.borderLight, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) Ripple preview")
    }

    private var previewFill: Color {
        Color(light: Color.white, dark: Color(hex: "101827"))
    }

    private var skeletonBars: some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 10.9)
                .fill(Color.widgetBorder.opacity(0.7))
                .frame(width: 31, height: 3.6)
            RoundedRectangle(cornerRadius: 10.9)
                .fill(Color.widgetBorder.opacity(0.55))
                .frame(width: 25, height: 3.6)
        }
    }
}

struct ComplicationWidget_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 23) {
            ComplicationWidget(title: "Circular", tier: .calm)
            ComplicationWidget(title: "Graphic", tier: .neutral)
        }
        .padding()
        .background(Color.adaptiveSettingsBackground)
    }
}
