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
                .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 5.71, x: 0, y: 2.85)
                .shadow(color: Color.settingsCardShadowColor.opacity(0.04), radius: 5.71, x: 0, y: 5.71)

            // Content
            VStack(alignment: .leading, spacing: 11) {
                // Title
                Text("Recommendations:")
                    .font(.custom("Roboto-Bold", size: 23.723))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .tracking(-0.3558)

                // Bullet list
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 0) {
                            Text("•")
                                .font(.custom("Roboto-Regular", size: 14))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                                .frame(width: 21, alignment: .leading)

                            Text(recommendation)
                                .font(.custom("Roboto-Regular", size: 14))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                                .tracking(-0.21)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 31.935)
                    }
                }
            }
            .padding(.leading, 29)
            .padding(.top, 24.24)
            .frame(width: 300.714, alignment: .leading)

            // FAQ link (bottom right)
            Button(action: { onFAQTap?() }) {
                HStack(spacing: 6) {
                    Text("FAQ")
                        .font(.custom("Roboto-Bold", size: 14.599))
                        .foregroundStyle(.black.opacity(0.39))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10.949, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.39))
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.bottom, 19.24)
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
