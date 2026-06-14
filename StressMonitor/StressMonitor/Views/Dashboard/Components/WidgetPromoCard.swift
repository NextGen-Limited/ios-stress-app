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
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.premiumGold)
                        .tracking(-0.27)

                    Text("Widgets that nudge you with insights")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textDescriptive)
                        .tracking(-0.195)
                }

                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .frame(width: 358, height: 86)
            .background(Color.Wellness.adaptiveCardBackground)
            .cornerRadius(20)
            .settingsCardDoubleShadow()
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
