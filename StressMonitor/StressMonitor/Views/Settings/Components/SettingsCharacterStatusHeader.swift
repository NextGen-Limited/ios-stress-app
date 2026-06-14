import SwiftUI

/// Friendly Ripple status header shown at the top of Settings.
struct SettingsCharacterStatusHeader: View {
    let stressLevel: Double
    let action: () -> Void

    private var tier: StressTier {
        StressTier.from(level: stressLevel)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tier.color.opacity(0.18))
                        .frame(width: 64, height: 64)
                        .blur(radius: 8)

                    RippleMoodFace(tier: tier, size: 56, showsRing: true, glow: true)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ripple is feeling")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("\(tier.emoji) \(settingsMoodTitle)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Tap to return to your dashboard")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.settingsRippleBlue)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.settingsRippleBlue)
                    .padding(8)
                    .background(Color.settingsRippleBlue.opacity(0.13), in: Circle())
            }
            .padding(18)
            .background(headerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.settingsCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ripple is feeling \(tier.label). Tap to return to dashboard.")
    }

    private var settingsMoodTitle: String {
        switch tier {
        case .veryCalm:
            return "Rested & Calm"
        case .calm:
            return "Calm & Content"
        case .neutral:
            return "Steady & Aware"
        case .stressed:
            return "Needs a Breather"
        case .critical:
            return "Moving Slowly"
        }
    }

    private var headerBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.settingsRippleBlue.opacity(0.16),
                Color.settingsCardBackground.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SettingsCharacterStatusHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SettingsCharacterStatusHeader(stressLevel: 35, action: {})
            SettingsCharacterStatusHeader(stressLevel: 86, action: {})
        }
        .padding()
        .background(Color.adaptiveSettingsBackground)
    }
}
