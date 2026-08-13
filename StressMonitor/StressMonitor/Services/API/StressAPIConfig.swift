import Foundation

// MARK: - Stress API Configuration

/// Centralized configuration for the standalone StressMonitor backend.
/// Resolves the base URL via a 3-tier lookup:
/// Info.plist build setting → process environment → UserDefaults → fallback.
enum StressAPIConfig {
    static let baseURL = URL(string: configuredString(
        infoPlistKey: "STRESS_API_BASE_URL",
        environmentKey: "STRESS_API_BASE_URL",
        userDefaultsKey: "stressAPIBaseURL",
        fallback: "https://stress-api.dropitx.site"
    ))!

    // MARK: - Endpoints

    static let healthURL = baseURL.appendingPathComponent("health")
    static let chatURL = baseURL.appendingPathComponent("chat")

    /// The fallback URL is always valid, so the service is always configured.
    static var isConfigured: Bool { true }

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
