import SwiftUI

struct MiniWalkInstructionCard: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.custom("Roboto-MediumItalic", size: 18))
            .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 33)
                    .fill(Color.Wellness.adaptiveCardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 7, y: 7)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 5)
            )
            .padding(.horizontal, 16)
    }
}
