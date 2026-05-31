import SwiftUI

/// Tab bar items matching Figma design
enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Tab Properties

    var title: String {
        switch self {
        case .home:    return "Home"
        case .action:  return "Action"
        case .trend:   return "Trend"
        }
    }

    // MARK: - Icon Name (used by DropletButton)
    var iconName: String {
        switch self {
        case .home:    return "home"
        case .action:  return "action"
        case .trend:   return "trend"
        }
    }

    // MARK: - Color for selected state
    var selectedColor: Color {
        Color.primaryBlue
    }

    // MARK: - Accessibility
    var accessibilityLabel: String {
        switch self {
        case .home:    return "Home tab, current stress level"
        case .action:  return "Action tab, quick actions and exercises"
        case .trend:   return "Trend tab, trends and insights"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:    return "Double tap to view current stress measurement"
        case .action:  return "Double tap to access quick actions and exercises"
        case .trend:   return "Double tap to view stress trends and history"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:    return "HomeTab"
        case .action:  return "ActionTab"
        case .trend:   return "TrendTab"
        }
    }
}
