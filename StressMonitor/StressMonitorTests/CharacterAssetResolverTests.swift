import Testing
@testable import StressMonitor

struct CharacterAssetResolverTests {
    @Test("Resolves full asset name for valid combination")
    func resolvesFullAssetName() {
        let name = CharacterAssetResolver.assetName(
            characterId: "ripple",
            evolution: .droplet,
            mood: .calm
        )

        #expect(name == "ripple_droplet_calm")
    }

    @Test("Resolves tidal overwhelmed asset")
    func resolvesTidalOverwhelmed() {
        let name = CharacterAssetResolver.assetName(
            characterId: "ember",
            evolution: .tidal,
            mood: .overwhelmed
        )

        #expect(name == "ember_tidal_overwhelmed")
    }

    @Test("Returns character calm fallback when exact asset is missing")
    func returnsCharacterFallbackWhenAssetMissing() {
        let name = CharacterAssetResolver.resolvedAssetName(
            characterId: "lumi",
            evolution: .tidal,
            mood: .worried
        )

        #expect(name == "lumi_droplet_calm")
    }

    @Test("All characters have valid naming pattern")
    func allCharactersValidNaming() {
        for creature in CharacterCreature.allCharacters {
            for evolution in EvolutionStage.allCases {
                for mood in StressBuddyMood.allCases {
                    let name = CharacterAssetResolver.assetName(
                        characterId: creature.id,
                        evolution: evolution,
                        mood: mood
                    )
                    #expect(!name.isEmpty)
                    #expect(name.contains(creature.id))
                    #expect(name.contains(evolution.rawValue))
                    #expect(name.contains(mood.rawValue))
                }
            }
        }
    }
}
