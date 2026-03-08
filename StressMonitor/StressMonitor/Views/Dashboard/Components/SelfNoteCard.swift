import SwiftUI

/// Self note card - "How do you feel?" prompt
/// Figma: 358pt × 80pt, teal bg (#85c9c9), white text, chevron arrow
struct SelfNoteCard: View {
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack {
                // Avatar circle with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B5FFC9"), Color(hex: "85C9C9")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44.638, height: 44.638)
                }

                // Text content
                VStack(alignment: .leading, spacing: 0) {
                    Text("How do you feel?")
                        .font(.custom("Lato-Regular", size: 13))
                        .foregroundStyle(.white)
                        .tracking(-0.195)

                    Text("Tell me about it")
                        .font(.custom("Lato-Bold", size: 16))
                        .foregroundStyle(.white)
                        .tracking(-0.24)
                }
                .padding(.leading, 24.105)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11.606, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(90))
            }
            .padding(.leading, 26.783)
            .padding(.trailing, 17.855)
            .padding(.top, 20)
            .padding(.bottom, 17.855)
            .frame(width: 358, height: 80)
            .background(Color.accentTeal)
            .cornerRadius(20)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
            .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("How do you feel? Tell me about it")
        .accessibilityHint("Double tap to share how you're feeling")
    }
}

// MARK: - Preview

#Preview("SelfNoteCard") {
    SelfNoteCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
