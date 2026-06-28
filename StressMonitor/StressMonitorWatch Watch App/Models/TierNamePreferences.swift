import Foundation

// MARK: - TierNamePreferences

/// User-editable display names for the watch's stress tiers. Stored as a
/// Codable blob in `UserDefaults` so it survives relaunches and can be
/// synced via `WatchConnectivity`.
///
/// Only the four primary tiers are user-editable; `.severe` always falls
/// back to its default label to preserve the safety-critical high-stress
/// signal.
struct TierNamePreferences: Codable, Sendable, Equatable {
    var relaxed: String  = "Relaxed"
    var mild: String     = "Mild"
    var moderate: String = "Moderate"
    var high: String     = "High"

    init(
        relaxed: String  = "Relaxed",
        mild: String     = "Mild",
        moderate: String = "Moderate",
        high: String     = "High"
    ) {
        self.relaxed  = relaxed
        self.mild     = mild
        self.moderate = moderate
        self.high     = high
    }

    /// Resolve the user-facing label for a given watch stress category.
    /// Empty custom names fall back to the tier default.
    func displayName(for category: WatchStressCategory) -> String {
        switch category {
        case .relaxed:  return relaxed.isEmpty  ? "Relaxed"  : relaxed
        case .mild:     return mild.isEmpty     ? "Mild"     : mild
        case .moderate: return moderate.isEmpty ? "Moderate" : moderate
        case .high:     return high.isEmpty     ? "High"     : high
        case .severe:   return "Severe"
        }
    }
}

// MARK: - UserDefaults persistence

extension TierNamePreferences {
    /// Storage key shared with the iOS app.
    static let defaultsKey = "watch.tierNamePreferences"

    /// Shared watch `UserDefaults` suit (matches `WatchFacePreferences`).
    private static var defaults: UserDefaults {
        UserDefaults.standard
    }

    /// Load persisted preferences, or the defaults if nothing is stored.
    static func load() -> TierNamePreferences {
        guard
            let data = defaults.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode(TierNamePreferences.self, from: data)
        else {
            return TierNamePreferences()
        }
        return decoded
    }

    /// Persist the current preferences.
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            Self.defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
