import SwiftUI

/// Small cat mascot + speech bubble shown below the premium banner
struct MascotSpeechBubbleView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("CharacterConcerned")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)

            Text(message)
                .font(Typography.caption1)
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderLight, lineWidth: 0.5)
                )
        }
    }
}

#Preview {
    MascotSpeechBubbleView(
        message: "I've been keeping an eye on your days! Want to see how stress changed this week?"
    )
    .padding()
    .background(Color.backgroundLight)
}
