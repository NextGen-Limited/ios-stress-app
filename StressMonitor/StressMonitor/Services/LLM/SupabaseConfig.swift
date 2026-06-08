import Foundation

// MARK: - Supabase Configuration

/// Centralized Supabase backend configuration.
/// Points to the StressMonitor Supabase project.
enum SupabaseConfig {
    static let url = URL(string: "https://fqurrfnfczeozvaxjrcu.supabase.co")!

    // Supabase anon/public key (safe to embed — restricted by RLS)
    // This is the standard anon key from the Supabase project dashboard
    static let anonKey = ""

    // Edge Function base URL
    static let functionsBaseURL = url.appendingPathComponent("functions/v1")

    // MARK: - Edge Function Endpoints

    static let healthURL = functionsBaseURL.appendingPathComponent("health")
    static let chatURL = functionsBaseURL.appendingPathComponent("chat")
    static let sessionsURL = functionsBaseURL.appendingPathComponent("sessions")
    static let preferencesURL = functionsBaseURL.appendingPathComponent("preferences")
    static let creditsURL = functionsBaseURL.appendingPathComponent("credits")
    static let quickActionsURL = functionsBaseURL.appendingPathComponent("quick-actions")
}
