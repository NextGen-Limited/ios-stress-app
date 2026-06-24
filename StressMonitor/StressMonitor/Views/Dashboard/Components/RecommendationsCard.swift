import SwiftUI

/// Recommendations card with bulleted list
/// Figma: 358pt × 234pt, white bg, title + bullet list + FAQ link
struct RecommendationsCard: View {
    let recommendations: [String]
    var onFAQTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            // White background card
            Color.white
                .cornerRadius(20)
                .settingsCardDoubleShadow()

            // Content
            VStack(alignment: .leading, spacing: 11) {
                // Title
                Text("Recommendations:")
                    .font(.system(size: 23.723, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .tracking(-0.3558)

                // Bullet list
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 0) {
                            Text("•")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                                .frame(width: 21, alignment: .leading)

                            Text(recommendation)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                                .tracking(-0.21)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 31.935)
                    }
                }
            }
            .padding(.leading, 29)
            .padding(.top, 24)
            .frame(width: 300.714, alignment: .leading)

            // FAQ link (bottom right)
            Button(action: { onFAQTap?() }) {
                HStack(spacing: 6) {
                    Text("FAQ")
                        .font(.system(size: 14.599, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.39))

                    Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                        .font(.system(size: 10.949, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.39))
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.bottom, 20)
            .padding(.trailing, 16)
        }
        .frame(width: 358, height: 234)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recommendations: \(recommendations.joined(separator: ", "))")
    }
}

// MARK: - Preview

#Preview("RecommendationsCard") {
    RecommendationsCard(
        recommendations: [
            "Dorem ipsum dolor sit amet",
            "consectetur adipiscing elit",
            "Nunc vulputate libero et velit interdum",
            "ac aliquet odio mattis."
        ]
    )
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
