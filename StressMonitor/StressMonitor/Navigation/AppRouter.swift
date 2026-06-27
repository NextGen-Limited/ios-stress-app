import Observation
import SwiftUI

/// Central, observable navigation state for the whole app.
///
/// Owns:
/// - the selected tab (`selectedTab`)
/// - one `NavigationPath` per primary tab, bound to that tab's `NavigationStack`
///
/// Injected once at the app root via `.environment(AppRouter())`. Any view can
/// drive navigation by reading the router from the environment — this is what
/// makes programmatic navigation, deep links, and cross-tab routing possible
/// without scattering `@State` booleans through leaf views.
@MainActor
@Observable
final class AppRouter {
    /// Currently active tab.
    var selectedTab: TabItem = .home

    /// Per-tab navigation paths. Bound to each tab's `NavigationStack(path:)`.
    var homePath = NavigationPath()
    var actionPath = NavigationPath()
    var trendsPath = NavigationPath()
    var settingsPath = NavigationPath()

    /// Switch the visible tab.
    func switchTab(_ tab: TabItem) {
        selectedTab = tab
    }

    /// Push `route` onto the path of `tab`, switching to that tab first.
    /// Use this for deep links (notifications, widgets, URL schemes) and any
    /// "go to X from anywhere" flow.
    func deepLink(to route: Route, in tab: TabItem) {
        selectedTab = tab
        switch tab {
        case .home:     homePath.append(route)
        case .action:   actionPath.append(route)
        case .trend:    trendsPath.append(route)
        case .settings: settingsPath.append(route)
        }
    }

    /// Binding-friendly mutator used by `NavigationStack(path:)`.
    func binding(for tab: TabItem) -> Binding<NavigationPath> {
        switch tab {
        case .home:     return Binding(get: { self.homePath },     set: { self.homePath = $0 })
        case .action:   return Binding(get: { self.actionPath },   set: { self.actionPath = $0 })
        case .trend:    return Binding(get: { self.trendsPath },   set: { self.trendsPath = $0 })
        case .settings: return Binding(get: { self.settingsPath }, set: { self.settingsPath = $0 })
        }
    }

    // MARK: - State restoration
    //
    // `Route` is `Codable`, so each `NavigationPath` can be serialized via its
    // `codable` representation. The snapshot is a single `Data` blob per tab,
    // stored in `@SceneStorage` by the host (see `MainTabView`). Decoding is
    // defensive: corrupt or schema-shifted data is dropped rather than
    // crashed (Axiom nav.md CRITICAL #8).

    /// Encodes a path to `Data`, or `nil` if the path is empty.
    static func encodePath(_ path: NavigationPath) -> Data? {
        guard !path.isEmpty else { return nil }
        return try? JSONEncoder().encode(path.codable)
    }

    /// Decodes a path from `Data`. Returns an empty path on any failure
    /// (missing data, schema change, deleted referenced item).
    static func decodePath(_ data: Data?) -> NavigationPath {
        guard let data,
              let codable = try? JSONDecoder().decode(
                  NavigationPath.CodableRepresentation.self,
                  from: data
              )
        else { return NavigationPath() }
        return NavigationPath(codable)
    }
}
