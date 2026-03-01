import SwiftUI
import SwiftData

/// Tab bar items matching Figma design
/// Conforms to Tabbable protocol for StressTabBarView compatibility
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    var id: Int { rawValue }

    // MARK: - Tabbable Protocol

    /// Icon asset name for TabBar library compatibility
    var icon: String { iconName }

    /// Title for TabBar library compatibility
    var title: String {
        switch self {
        case .home: return "Home"
        case .action: return "Action"
        case .trend: return "Trends"
        }
    }

    // MARK: - Custom Properties

    /// Asset name in Asset Catalog
    var iconName: String {
        switch self {
        case .home:   return "TabHome"
        case .action: return "TabAction"
        case .trend:  return "TabTrend"
        }
    }

    /// Accessibility label (WCAG AA)
    var accessibilityLabel: String {
        switch self {
        case .home:   return "Home tab, current stress level"
        case .action: return "Action tab, quick actions and exercises"
        case .trend:  return "Trend tab, trends and insights"
        }
    }

    /// Hint for VoiceOver
    var accessibilityHint: String {
        switch self {
        case .home:   return "Double tap to view current stress measurement"
        case .action: return "Double tap to access quick actions"
        case .trend:  return "Double tap to view stress trends and history"
        }
    }

    /// Accessibility identifier for UI testing
    var accessibilityIdentifier: String {
        switch self {
        case .home:   return "HomeTab"
        case .action: return "ActionTab"
        case .trend:  return "TrendTab"
        }
    }

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
}
