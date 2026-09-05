import SwiftUI

/// AI Chat card matching Figma node 3365-9941
/// Card: 358pt wide, mascot top-right, text content left, CTA button, disclaimer footer
struct AIChatCard: View {
    var onTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Ripple water-droplet mascot — positioned top-right, overlapping text area
            StressBuddyIllustration(mood: .serene, size: 128)
                .offset(x: 8, y: 40)

            // Content column
            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text("AI Chat")
                    .font(Font.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "777986"))
                    .tracking(-0.36)
                    .padding(.top, 19)
                    .padding(.leading, 28)

                // Subtitle
                Text("Talk with Ripple")
                    .font(Font.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .tracking(-0.21)
                    .padding(.top, 7)
                    .padding(.leading, 28)

                // Description
                Text("\"It's always better to talk to your support group. If you need, Ripple is here for you!\"")
                    .font(Font.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .tracking(-0.195)
                    .frame(width: 203, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
                    .padding(.leading, 28)

                // CTA Button
                Button(action: { onTap?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 11))

                        Text("Chat with Ripple")
                            .font(Font.system(size: 14, weight: .medium, design: .rounded))
                            .tracking(-0.21)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 181, height: 37)
                    .background(Color.accentTeal)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                .padding(.leading, 28)

                Spacer(minLength: 0)

                // Disclaimer
                VStack(spacing: 2) {
                    Text("For informational purposes only.")
                        .font(Font.system(size: 10, weight: .light, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .tracking(-0.15)

                    Text("Tap here if you need medical or therapy resource")
                        .font(Font.system(size: 10, weight: .light, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        .tracking(-0.15)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 358, height: 258)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.7, x: 0, y: 5.7)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 2.85, x: 0, y: 2.85)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Chat. Talk with Ripple")
        .accessibilityHint("Double tap to start chatting")
    }
}

#Preview("AIChatCard") {
    AIChatCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
