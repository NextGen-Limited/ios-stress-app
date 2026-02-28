import SwiftUI

// MARK: - Stress Buddy Character Illustration

/// Character illustration using SVG assets from Figma design
/// Displays the Stress Buddy mascot with mood-based expressions
/// Supports animation via CharacterAnimationModifier
struct StressBuddyIllustration: View {
    let mood: StressBuddyMood
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .characterAnimation(for: mood)
    }

    /// Maps mood to corresponding asset name
    private var assetName: String {
        switch mood {
        case .sleeping:
            return "CharacterSleeping"
        case .calm:
            return "CharacterCalm"
        case .concerned:
            return "CharacterConcerned"
        case .worried:
            return "CharacterWorried"
        case .overwhelmed:
            return "CharacterOverwhelmed"
        }
    }
}

// MARK: - Preview

#Preview("All Moods") {
    HStack(spacing: 20) {
        ForEach(StressBuddyMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
                Text(mood.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark Mode") {
    HStack(spacing: 20) {
        ForEach(StressBuddyMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
                Text(mood.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
    .preferredColorScheme(.dark)
}
