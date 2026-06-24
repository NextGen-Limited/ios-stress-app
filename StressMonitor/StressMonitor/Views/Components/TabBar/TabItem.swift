import SwiftUI

/// Tab bar items rendered with SF Symbols (no PNG assets).
/// Characters live in Settings, keeping the tab bar focused on the three
/// primary destinations plus a first-class Settings entry.
enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2
    case settings = 3

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Tab Properties

    var title: String {
        switch self {
        case .home:       return "Home"
        case .action:     return "Action"
        case .trend:      return "Trends"
        case .settings:   return "Settings"
        }
    }

    // MARK: - SF Symbol names

    /// SF Symbol for the unselected state.
    var sfSymbol: String {
        switch self {
        case .home:       return AppIconSystem.Tab.home.sfSymbol
        case .action:     return AppIconSystem.Tab.action.sfSymbol
        case .trend:      return AppIconSystem.Tab.trends.sfSymbol
        case .settings:   return AppIconSystem.Tab.settings.sfSymbol
        }
    }

    /// SF Symbol for the selected state (filled variant).
    var sfSymbolActive: String {
        switch self {
        case .home:       return AppIconSystem.Tab.home.sfSymbolActive
        case .action:     return AppIconSystem.Tab.action.sfSymbolActive
        case .trend:      return AppIconSystem.Tab.trends.sfSymbolActive
        case .settings:   return AppIconSystem.Tab.settings.sfSymbolActive
        }
    }

    // MARK: - Color for selected state
    var selectedColor: Color {
        Color.primaryBlue
    }

    // MARK: - Accessibility
    var accessibilityLabel: String {
        switch self {
        case .home:       return "Home tab, current stress level"
        case .action:     return "Action tab, quick actions and exercises"
        case .trend:      return "Trends tab, trends and insights"
        case .settings:   return "Settings tab, preferences and character collection"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:       return "Double tap to view current stress measurement"
        case .action:     return "Double tap to access quick actions and exercises"
        case .trend:      return "Double tap to view stress trends and history"
        case .settings:   return "Double tap to open settings and the character collection"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:       return "HomeTab"
        case .action:     return "ActionTab"
        case .trend:      return "TrendTab"
        case .settings:   return "SettingsTab"
        }
    }
}
