import SwiftUI
import SwiftData

/// Tab bar items matching Figma design
enum TabItem: Int, Tabbable, CaseIterable, Identifiable {
    case home = 0
    case action = 1
    case trend = 2
    case history = 3
    case settings = 4

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Tabbable Protocol
    var icon: String { unselectedIconName }

    var title: String {
        switch self {
        case .home:    return "Home"
        case .action:  return "Action"
        case .trend:   return "Trend"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    // MARK: - Icon Names (custom images for main tabs, SF Symbols for others)
    var selectedIconName: String {
        switch self {
        case .home:    return "home-selected"
        case .action:  return "action-selected"
        case .trend:   return "trend-selected"
        case .history: return "clock.badge.checkmark"
        case .settings: return "gearshape.fill"
        }
    }

    var unselectedIconName: String {
        switch self {
        case .home:    return "home"
        case .action:  return "action"
        case .trend:   return "trend"
        case .history: return "clock"
        case .settings: return "gearshape"
        }
    }

    // MARK: - Use SF Symbols (for history and settings)
    var useSymbol: Bool {
        switch self {
        case .home, .action, .trend:
            return false
        case .history, .settings:
            return true
        }
    }

    // MARK: - Color for selected state
    var selectedColor: Color {
        switch self {
        case .home, .action, .trend:
            return Color.primaryBlue
        case .history, .settings:
            return Color.primaryBlue
        }
    }

    // MARK: - Accessibility
    var accessibilityLabel: String {
        switch self {
        case .home:    return "Home tab, current stress level"
        case .action:  return "Action tab, quick actions and exercises"
        case .trend:   return "Trend tab, trends and insights"
        case .history: return "History tab, past measurements"
        case .settings: return "Settings tab, app settings"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:    return "Double tap to view current stress measurement"
        case .action:  return "Double tap to access quick actions and exercises"
        case .trend:   return "Double tap to view stress trends and history"
        case .history: return "Double tap to view measurement history"
        case .settings: return "Double tap to open settings"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:    return "HomeTab"
        case .action:  return "ActionTab"
        case .trend:   return "TrendTab"
        case .history: return "HistoryTab"
        case .settings: return "SettingsTab"
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
        case .history:
            MeasurementHistoryView()
        case .settings:
            SettingsView()
        }
    }
}
