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
    /// Canonical droplet-stage fallback mood used when a more specific asset
    /// is missing. The bundled placeholder assets are named with the legacy
    /// `calm` slug, so the fallback references that slug directly rather than
    /// regenerating from a `RippleMood` value.
    private static let fallbackDropletSlug = "calm"

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
        mood: RippleMood
    ) -> String {
        "\(characterId)_\(evolution.rawValue)_\(mood.rawValue)"
    }

    /// Resolve the best available asset name using the project fallback chain.
    static func resolvedAssetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: RippleMood,
        bundle: Bundle = .main
    ) -> String {
        let exact = assetName(characterId: characterId, evolution: evolution, mood: mood)
        if assetExists(named: exact, in: bundle) {
            return exact
        }

        let characterFallback = "\(characterId)_\(EvolutionStage.droplet.rawValue)_\(fallbackDropletSlug)"
        if assetExists(named: characterFallback, in: bundle) {
            return characterFallback
        }

        let legacy = legacyAssetName(for: mood)
        if assetExists(named: legacy, in: bundle) {
            return legacy
        }

        return "CharacterCalm"
    }

    static func legacyAssetName(for mood: RippleMood) -> String {
        switch mood {
        case .relaxed:      return "CharacterSleeping"
        case .serene:       return "CharacterCalm"
        case .focused:      return "CharacterConcerned"
        case .worried:      return "CharacterWorried"
        case .celebrating:  return "CharacterOverwhelmed"
        case .happy:        return "CharacterCalm"
        case .determined:   return "CharacterOverwhelmed"
        case .tired:        return "CharacterSleeping"
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
