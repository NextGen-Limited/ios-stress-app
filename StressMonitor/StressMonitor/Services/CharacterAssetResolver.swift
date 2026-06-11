import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Resolves character asset names from a `(characterId, evolution, mood)` tuple.
///
/// Naming convention: `{characterId}_{evolution}_{mood}`.
/// Fallback chain:
/// 1. Exact character/evolution/mood asset
/// 2. Character starter calm asset (`{characterId}_droplet_calm`)
/// 3. Legacy generic mood asset (`CharacterCalm`, etc.)
/// 4. Legacy generic calm asset
public enum CharacterAssetResolver {
    private static let placeholderCharacterAssets: Set<String> = [
        "ripple_droplet_calm",
        "blossom_droplet_calm",
        "ember_droplet_calm",
        "zephyr_droplet_calm",
        "lumi_droplet_calm",
    ]

    private static let legacyMoodAssets: Set<String> = [
        "CharacterSleeping",
        "CharacterCalm",
        "CharacterConcerned",
        "CharacterWorried",
        "CharacterOverwhelmed",
    ]

    /// Generate the canonical asset name for a specific character state.
    static func assetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: StressBuddyMood
    ) -> String {
        "\(characterId)_\(evolution.rawValue)_\(mood.rawValue)"
    }

    /// Resolve the best available asset name using the project fallback chain.
    static func resolvedAssetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: StressBuddyMood,
        bundle: Bundle = .main
    ) -> String {
        let exact = assetName(characterId: characterId, evolution: evolution, mood: mood)
        if assetExists(named: exact, in: bundle) {
            return exact
        }

        let characterFallback = assetName(characterId: characterId, evolution: .droplet, mood: .calm)
        if assetExists(named: characterFallback, in: bundle) {
            return characterFallback
        }

        let legacy = legacyAssetName(for: mood)
        if assetExists(named: legacy, in: bundle) {
            return legacy
        }

        return "CharacterCalm"
    }

    static func legacyAssetName(for mood: StressBuddyMood) -> String {
        switch mood {
        case .sleeping: return "CharacterSleeping"
        case .calm: return "CharacterCalm"
        case .concerned: return "CharacterConcerned"
        case .worried: return "CharacterWorried"
        case .overwhelmed: return "CharacterOverwhelmed"
        }
    }

    private static func assetExists(named name: String, in bundle: Bundle) -> Bool {
        if placeholderCharacterAssets.contains(name) || legacyMoodAssets.contains(name) {
            return true
        }

        #if canImport(UIKit)
        return UIImage(named: name, in: bundle, compatibleWith: nil) != nil
        #else
        return false
        #endif
    }
}
