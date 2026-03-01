import SwiftUI
import SwiftData

/// Tab bar items matching Figma design
/// Conforms to Tabbable protocol for StressTabBarView compatibility
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2
}

// MARK: - Tabbable Protocol

/// Icon asset name for TabBar compatibility (deprecated, use selectedIcon/unselectedIcon)
var icon: String { iconName }

// MARK: - Custom Properties

var title: String {
    switch self {
    case .home:   return "Home"
    case .action: return "Action"
    case .trend: return "Trend"
    }
}

// MARK: - Computed Properties (new approach)

/// Asset name for selected state (from Assets.xcassets/TabBar/)
var selectedIconName: String {
    switch self {
    case .home:   return "home-selected"
    case .action: return "action-selected"
    case .trend:   return "trend-selected"
    }
}

/// Asset name for unselected state (from Assets.xcassets/TabBar/)
var unselectedIconName: String {
    switch self {
    case .home:   return "home"
    case .action: return "action"
    case .trend:   return "trend"
    }
}

// MARK: - Accessibility

/// Accessibility label (WCAG AA)
var accessibilityLabel: String {
    switch self {
    case .home:   return "Home tab, current stress level"
    case .action: return "Action tab, quick actions and exercises"
    case .trend: return "Trend tab, trends and insights"
    }
}

/// Accessibility hint for VoiceOver
var accessibilityHint: String {
    switch self {
    case .home:   return "Double tap to view current stress measurement"
    case .action: return "Double tap to access quick actions and exercises"
    case .trend: return "Double tap to view stress trends and history"
    }
}

/// Accessibility identifier for UI testing
var accessibilityIdentifier: String {
    switch self {
    case .home:   return "HomeTab"
    case .action: return "ActionTab"
    case .trend: return "TrendTab"
    }
}

// MARK: - View Builder

/// View to display when tab is selected
@ViewBuilder
func destinationView(modelContext: ModelContext, useMockData: Bool) -> some View {
    switch self {
    case .home:
        if useMockData {
            DashboardView(viewModel: PreviewDataFactory.mockDashboardViewModel())
        } else {
            DashboardView(repository: StressRepository(modelContext: modelContext))
        }
    case .action:
        ActionView()
    case .trend:
        TrendsView()
    }
}
