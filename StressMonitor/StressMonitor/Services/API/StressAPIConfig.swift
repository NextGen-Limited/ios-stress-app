import Foundation

// MARK: - Stress API Configuration

/// Centralized configuration for the standalone StressMonitor backend.
/// Resolves the base URL via a 3-tier lookup:
/// Info.plist build setting → process environment → UserDefaults → fallback.
enum StressAPIConfig {
    static let baseURL: URL = resolveBaseURL(
        infoPlistValue: Bundle.main.object(forInfoDictionaryKey: "STRESS_API_BASE_URL") as? String,
        environmentValue: ProcessInfo.processInfo.environment["STRESS_API_BASE_URL"],
        userDefaultsValue: UserDefaults.standard.string(forKey: "stressAPIBaseURL"),
        fallback: "https://stress-api.dropitx.site"
    )

    // MARK: - Endpoints

    static let healthURL = baseURL.appendingPathComponent("health")
    static let chatURL = baseURL.appendingPathComponent("chat")

    /// The fallback URL is always valid, so the service is always configured.
    static var isConfigured: Bool { true }

    /// Testable 3-tier resolution seam (D-03): Info.plist → environment →
    /// UserDefaults → fallback. The static `baseURL` captures the resolved
    /// value at type-load time, so precedence is asserted against this helper
    /// rather than the captured property.
    static func resolveBaseURL(
        infoPlistValue: String?,
        environmentValue: String?,
        userDefaultsValue: String?,
        fallback: String
    ) -> URL {
        let resolved = resolveString(
            infoPlistValue: infoPlistValue,
            environmentValue: environmentValue,
            userDefaultsValue: userDefaultsValue,
            fallback: fallback
        )
        return URL(string: resolved)!
    }

    private static func resolveString(
        infoPlistValue: String?,
        environmentValue: String?,
        userDefaultsValue: String?,
        fallback: String
    ) -> String {
        if let infoPlistValue,
           !infoPlistValue.isEmpty,
           !infoPlistValue.hasPrefix("$(") {
            return infoPlistValue
        }

        if let environmentValue, !environmentValue.isEmpty {
            return environmentValue
        }

        if let userDefaultsValue, !userDefaultsValue.isEmpty {
            return userDefaultsValue
        }

        return fallback
    }
}
