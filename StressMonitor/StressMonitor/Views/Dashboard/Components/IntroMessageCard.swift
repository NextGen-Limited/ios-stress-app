import SwiftUI

/// Introductory message card with cat mascot and speech bubble
/// Figma: White card with cat illustration and personalized greeting
struct IntroMessageCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Cat mascot placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "cat.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "#333333"))
                )

            // Speech bubble
            VStack(alignment: .leading, spacing: 0) {
                Text("I've been keeping an eye on your days! Want to see how stress changed this week?")
                    .font(.custom("Roboto-Regular", size: 14))
                    .foregroundStyle(Color(hex: "#333333"))
                    .fixedSize(horizontal: false, vertical: false)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            // Speech bubble tail would be added with custom shape

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}

#Preview("IntroMessageCard") {
    IntroMessageCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
