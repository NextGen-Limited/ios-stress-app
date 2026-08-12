import Foundation

// MARK: - Supabase Configuration

/// Centralized Supabase backend configuration.
/// Points to the StressMonitor Supabase project.
enum SupabaseConfig {
    static let url = URL(string: configuredString(
        infoPlistKey: "SUPABASE_URL",
        environmentKey: "SUPABASE_URL",
        userDefaultsKey: "supabaseURL",
        fallback: "https://sxlaxpnyadellgyvxofm.supabase.co"
    ))!

    /// Masked placeholder used when no real anon key is configured. Exposed so
    /// `isConfigured` and tests can recognize it without hardcoding the literal
    /// in two places.
    static let maskedFallback = "**********************************************"

    // Supabase anon/public key (safe to embed only when restricted by RLS).
    // Do not hardcode project keys in source; provide via Info.plist build setting,
    // process environment for tests, or UserDefaults during local QA.
    static let anonKey = configuredString(
        infoPlistKey: "SUPABASE_ANON_KEY",
        environmentKey: "SUPABASE_ANON_KEY",
        userDefaultsKey: "supabaseAnonKey",
        fallback: maskedFallback
    )

    /// True only when a real anon key is resolved. The masked placeholder and
    /// asterisk-only strings read as "unconfigured" so `isAvailable` stays
    /// honest even before the `ChatAvailability` entry-point gate applies.
    static var isConfigured: Bool {
        let key = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return false }
        return !isMaskedPlaceholder(key)
    }

    /// Recognizes the masked fallback literal and any all-asterisks string.
    static func isMaskedPlaceholder(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == maskedFallback || trimmed.allSatisfy { $0 == "*" }
    }

    // Edge Function base URL
    static let functionsBaseURL = url.appendingPathComponent("functions/v1")

    // MARK: - Edge Function Endpoints

    static let healthURL = functionsBaseURL.appendingPathComponent("health")
    static let chatURL = functionsBaseURL.appendingPathComponent("chat")
    static let sessionsURL = functionsBaseURL.appendingPathComponent("sessions")
    static let preferencesURL = functionsBaseURL.appendingPathComponent("preferences")
    static let creditsURL = functionsBaseURL.appendingPathComponent("credits")
    static let quickActionsURL = functionsBaseURL.appendingPathComponent("quick-actions")

    private static func configuredString(
        infoPlistKey: String,
        environmentKey: String,
        userDefaultsKey: String,
        fallback: String
    ) -> String {
        if let value = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
           !value.isEmpty,
           !value.hasPrefix("$(") {
            return value
        }

        let environment = ProcessInfo.processInfo.environment[environmentKey]
        if let environment, !environment.isEmpty {
            return environment
        }

        let defaultsValue = UserDefaults.standard.string(forKey: userDefaultsKey)
        if let defaultsValue, !defaultsValue.isEmpty {
            return defaultsValue
        }

        return fallback
    }
}
