import Foundation

// MARK: - Supabase Configuration

/// Centralized Supabase backend configuration.
/// Points to the StressMonitor Supabase project.
enum SupabaseConfig {
    static let url = URL(string: configuredString(
        infoPlistKey: "SUPABASE_URL",
        environmentKey: "SUPABASE_URL",
        userDefaultsKey: "supabaseURL",
        fallback: "https://fqurrfnfczeozvaxjrcu.supabase.co"
    ))!

    // Supabase anon/public key (safe to embed only when restricted by RLS).
    // Do not hardcode project keys in source; provide via Info.plist build setting,
    // process environment for tests, or UserDefaults during local QA.
    static let anonKey = configuredString(
        infoPlistKey: "SUPABASE_ANON_KEY",
        environmentKey: "SUPABASE_ANON_KEY",
        userDefaultsKey: "supabaseAnonKey",
        fallback: ""
    )

    static var isConfigured: Bool {
        !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
