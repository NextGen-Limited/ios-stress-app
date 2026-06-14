import SwiftUI

/// Quote card with inspirational quote
/// Figma: 358pt × 97pt, cream bg (#E9DDCA)
struct QuoteCard: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 8) {
            Text("\"\(quote)\"")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .italic()
                .foregroundStyle(Color(hex: "796038"))
                .tracking(-0.21)
                .multilineTextAlignment(.center)
                .frame(width: 312)

            Text(author)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "796038"))
                .tracking(-0.21)
        }
        .frame(width: 358, height: 97)
        .padding(10)
        .background(Color(hex: "E9DDCA"))
        .cornerRadius(20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quote by \(author): \(quote)")
    }
}

// MARK: - Preview

#Preview("QuoteCard") {
    QuoteCard(
        quote: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
        author: "Nelson Mandela"
    )
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
