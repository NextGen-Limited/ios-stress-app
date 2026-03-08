import SwiftUI

/// AI Chat card for talking with AI assistant
/// Figma: 358pt × 258pt, white bg, cat mascot + title + description + button
struct AIChatCard: View {
    var onTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("AI Chat")
                .font(.custom("Lato-Bold", size: 24))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .tracking(-0.36)
                .padding(.leading, 28.29)
                .padding(.top, 19.16)

            // Subtitle
            Text("Talk with AI Kitten")
                .font(.custom("Lato-Regular", size: 14))
                .foregroundStyle(Color(hex: "808080"))
                .tracking(-0.21)
                .padding(.leading, 28.29)
                .padding(.top, 8)

            // Description quote
            Text("\"It's always better to talk to your support group. If you need, Kitten is here for you!\"")
                .font(.custom("Lato-Regular", size: 13))
                .foregroundStyle(Color(hex: "808080"))
                .tracking(-0.195)
                .frame(width: 203.471, alignment: .leading)
                .padding(.leading, 28.29)
                .padding(.top, 8)

            // Cat mascot placeholder (right side)
            ZStack {
                // Mascot image placeholder
                Image(systemName: "cat.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .foregroundStyle(Color.Wellness.gratitudePurple.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 0)
            .offset(y: -50)

            // Chat button
            Button(action: { onTap?() }) {
                HStack(spacing: 6.387) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10.949))

                    Text("Chat with StressCat")
                        .font(.custom("Lato-Semibold", size: 14))
                        .foregroundStyle(.white)
                        .tracking(-0.21)
                }
                .frame(width: 181, height: 37)
                .background(Color.accentTeal)
                .cornerRadius(21.655)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 154.05 - 50)

            // Footer text
            VStack(spacing: 4) {
                Text("For informational purposes only.")
                    .font(.custom("Lato-Regular", size: 10.037))
                    .foregroundStyle(Color(hex: "808080"))
                    .tracking(-0.15)

                Link(destination: URL(string: "settings:health")!) {
                    Text("Tap here if you need medical or therapy resource")
                        .font(.custom("Lato-Regular", size: 10.037))
                        .foregroundStyle(Color(hex: "A231CF"))
                        .underline()
                        .tracking(-0.15)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 215.33 - 154.05 + 50)
        }
        .frame(width: 358, height: 258.217)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
        .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Chat. Talk with AI Kitten")
        .accessibilityHint("Double tap to start chatting")
    }
}

// MARK: - Preview

#Preview("AIChatCard") {
    AIChatCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
