import SwiftUI

// MARK: - Character Illustration

/// Character illustration that renders the SwiftUI procedural character views
/// through the ``CharacterAssetResolver`` router.
///
/// Kept as a thin wrapper so existing call sites (dashboard gauge, character
/// collection, picker sheet, illustration exporter) can adopt the new
/// procedural views without each one switching on character id. When a
/// `characterId` is supplied the matching elemental creature is rendered;
/// otherwise the Ripple (water) character is used as the default.
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
        Group {
            if let characterId {
                if let evolution {
                    CharacterAssetResolver.characterView(
                        for: characterId,
                        evolution: evolution,
                        mood: mood,
                        size: size
                    )
                } else {
                    CharacterAssetResolver.characterView(
                        for: characterId,
                        mood: mood,
                        size: size
                    )
                }
            } else {
                CharacterAssetResolver.characterView(
                    for: "ripple",
                    mood: mood,
                    size: size
                )
            }
        }
        .frame(width: size, height: size)
        .characterAnimation(for: mood)
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
