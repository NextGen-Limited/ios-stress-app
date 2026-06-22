import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Resolves a character id to a SwiftUI character view (and, for legacy
/// callers, to a fallback asset name).
///
/// The canonical entry point is ``characterView(for:mood:size:)``, which
/// routes each character id to its procedural SwiftUI view. The legacy
/// `assetName`/`resolvedAssetName` helpers are retained in a deprecated
/// extension for callers that still resolve image assets.
public enum CharacterAssetResolver {

    /// Route a character id to its SwiftUI procedural view.
    ///
    /// Unknown ids fall back to the Ripple (water) character so the UI never
    /// renders empty when an id is stale or missing.
    static func characterView(for id: String, mood: RippleMood, size: CGFloat = 120) -> AnyView {
        switch id {
        case "ripple":  return AnyView(RippleCharacterView(mood: mood, size: size))
        case "blossom": return AnyView(BlossomCharacterView(mood: mood, size: size))
        case "ember":   return AnyView(EmberCharacterView(mood: mood, size: size))
        case "zephyr":  return AnyView(ZephyrCharacterView(mood: mood, size: size))
        case "lumi":    return AnyView(LumiCharacterView(mood: mood, size: size))
        default:        return AnyView(RippleCharacterView(mood: mood, size: size))
        }
    }

    /// Apply the per-evolution scale factor so callers can keep using the
    /// evolution metadata without reimplementing the size curve.
    static func characterView(
        for id: String,
        evolution: EvolutionStage,
        mood: RippleMood,
        size: CGFloat = 120
    ) -> AnyView {
        characterView(for: id, mood: mood, size: size * evolution.scaleFactor)
    }
}

// MARK: - Legacy Asset-Name Resolution

extension CharacterAssetResolver {

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
    ///
    /// - Deprecated: Prefer ``characterView(for:mood:size:)`` — characters
    ///   now render as SwiftUI procedural views. This helper is retained only
    ///   for the illustration export pipeline, which still rasterizes assets.
    @available(*, deprecated, message: "Use CharacterAssetResolver.characterView(for:mood:size:) for on-screen rendering.")
    static func assetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: RippleMood
    ) -> String {
        "\(characterId)_\(evolution.rawValue)_\(mood.rawValue)"
    }

    /// Resolve the best available asset name using the project fallback chain.
    ///
    /// - Deprecated: See ``assetName(characterId:evolution:mood:)``.
    @available(*, deprecated, message: "Use CharacterAssetResolver.characterView(for:mood:size:) for on-screen rendering.")
    static func resolvedAssetName(
        characterId: String,
        evolution: EvolutionStage,
        mood: RippleMood,
        bundle: Bundle = .main
    ) -> String {
        let exact = "\(characterId)_\(evolution.rawValue)_\(mood.rawValue)"
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
