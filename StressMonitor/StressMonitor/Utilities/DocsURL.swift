import Foundation

/// Centralized docs URL constants. Update `base` after Vercel deploy.
/// URLs are locale-aware: Vietnamese device → /vi/ prefix, others → English root.
enum DocsURL {
    static let base = URL(string: "https://stressmonitor-docs.vercel.app")!

    static var localePrefix: String {
        Locale.current.language.languageCode?.identifier == "vi" ? "/vi" : ""
    }

    static var help: URL         { base.appending(path: "\(localePrefix)/user-guide/") }
    static var principle: URL    { base.appending(path: "\(localePrefix)/principle/") }
    static var stressLevels: URL { base.appending(path: "\(localePrefix)/principle/stress-levels") }
    static var privacy: URL      { base.appending(path: "\(localePrefix)/legal/privacy") }
    static var terms: URL        { base.appending(path: "\(localePrefix)/legal/terms") }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
