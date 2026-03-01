import SwiftUI
import SwiftData

/// Tab bar items matching Figma design
/// Conforms to Tabbable protocol for StressTabBarView compatibility
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Tabbable Protocol
    var icon: String { unselectedIconName }

    var title: String {
        switch self {
        case .home:   return "Home"
        case .action: return "Action"
        case .trend:  return "Trend"
        }
    }

    // MARK: - Icon Names
    var selectedIconName: String {
        switch self {
        case .home:   return "home-selected"
        case .action: return "action-selected"
        case .trend:  return "trend-selected"
        }
    }

    var unselectedIconName: String {
        switch self {
        case .home:   return "home"
        case .action: return "action"
        case .trend:  return "trend"
        }
    }

    // MARK: - Accessibility
    var accessibilityLabel: String {
        switch self {
        case .home:   return "Home tab, current stress level"
        case .action: return "Action tab, quick actions and exercises"
        case .trend:  return "Trend tab, trends and insights"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:   return "Double tap to view current stress measurement"
        case .action: return "Double tap to access quick actions and exercises"
        case .trend:  return "Double tap to view stress trends and history"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:   return "HomeTab"
        case .action: return "ActionTab"
        case .trend:  return "TrendTab"
        }
    }

    // MARK: - View Builder
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
