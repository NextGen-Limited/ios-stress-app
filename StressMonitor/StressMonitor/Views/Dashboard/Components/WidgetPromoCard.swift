import SwiftUI

/// Widget promotion card
/// Figma: 358pt × 86pt, white bg, icon + title + description
struct WidgetPromoCard: View {
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 23) {
                // Icon
                Image("k-widget-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set widget now!")
                        .font(.custom("Roboto-Bold", size: 18))
                        .foregroundStyle(Color.premiumGold)
                        .tracking(-0.27)

                    Text("Widgets that nudge you with insights")
                        .font(.custom("Roboto-Regular", size: 13))
                        .foregroundStyle(Color.textDescriptive)
                        .tracking(-0.195)
                }

                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .frame(width: 358, height: 86)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Set widget now. Widgets that nudge you with insights")
        .accessibilityHint("Double tap to set up widgets")
    }
}

// MARK: - Preview

#Preview("WidgetPromoCard") {
    WidgetPromoCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
