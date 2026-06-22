import SwiftUI

// MARK: - Stress Buddy Character Illustration

/// Character illustration using SVG assets from the character asset pipeline.
/// Supports legacy generic buddy assets and new per-character assets.
struct StressBuddyIllustration: View {
    let mood: RippleMood
    let size: CGFloat
    let characterId: String?
    let evolution: EvolutionStage?

    init(mood: RippleMood, size: CGFloat) {
        self.mood = mood
        self.size = size
        self.characterId = nil
        self.evolution = nil
    }

    init(characterId: String, evolution: EvolutionStage, mood: RippleMood, size: CGFloat) {
        self.mood = mood
        self.size = size
        self.characterId = characterId
        self.evolution = evolution
    }

    var body: some View {
        Image(resolvedAssetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(evolution?.scaleFactor ?? 1)
            .characterAnimation(for: mood)
    }

    private var resolvedAssetName: String {
        guard let characterId, let evolution else {
            return CharacterAssetResolver.legacyAssetName(for: mood)
        }

        return CharacterAssetResolver.resolvedAssetName(
            characterId: characterId,
            evolution: evolution,
            mood: mood
        )
    }
}

// MARK: - Preview

#Preview("All Moods") {
    HStack(spacing: 20) {
        ForEach(RippleMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Ripple") {
    HStack(spacing: 20) {
        ForEach(RippleMood.allCases, id: \.self) { mood in
            StressBuddyIllustration(characterId: "ripple", evolution: .droplet, mood: mood, size: 120)
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark Mode") {
    HStack(spacing: 20) {
        ForEach(RippleMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
    .preferredColorScheme(.dark)
}
