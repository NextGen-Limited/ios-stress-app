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
                                colors: [Color(hex: "B5FFC9"), Color(hex: "4FC3F7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44.638, height: 44.638)
                }

                // Text content
                VStack(alignment: .leading, spacing: 0) {
                    Text("How do you feel?")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(-0.195)

                    Text("Tell me about it")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(-0.24)
                }
                .padding(.leading, 24)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11.606, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(90))
            }
            .padding(.leading, 28)
            .padding(.trailing, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(width: 358, height: 80)
            .background(Color.accentTeal)
            .cornerRadius(20)
            .settingsCardDoubleShadow()
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
