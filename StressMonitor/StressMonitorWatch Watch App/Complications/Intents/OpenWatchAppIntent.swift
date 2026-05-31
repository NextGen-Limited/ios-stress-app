import Foundation
import AppIntents
import WidgetKit

// MARK: - Open Watch App Intent
/// Simple AppIntent for deep linking from complications
/// Enables tappable complications that open the watch app
@available(watchOS 10.0, *)
struct OpenWatchAppIntent: AppIntent {

    // MARK: - AppIntent Configuration
    static var title: LocalizedStringResource = "Open Stress Monitor"
    static var description = IntentDescription("Opens the Stress Monitor app to view detailed stress information.")

    static var openAppWhenRun: Bool = true

    // MARK: - AppIntent Performance
    @MainActor
    func perform() async -> some IntentResult {
        return .result()
    }
}

// MARK: - Target Screen Enum
/// Defines available screens for deep linking
enum TargetScreen: String, AppEnum {
    case dashboard = "dashboard"
    case history = "history"
    case trends = "trends"
    case breathing = "breathing"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Screen")

    static var caseDisplayRepresentations: [TargetScreen: DisplayRepresentation] = [
        .dashboard: "Dashboard",
        .history: "History",
        .trends: "Trends",
        .breathing: "Breathing"
    ]

    /// Deep link URL for the target screen
    var deepLinkURL: URL {
        switch self {
        case .dashboard:
            return URL(string: "stressmonitor://dashboard")!
        case .history:
            return URL(string: "stressmonitor://history")!
        case .trends:
            return URL(string: "stressmonitor://trends")!
        case .breathing:
            return URL(string: "stressmonitor://breathing")!
        }
    }
}

// MARK: - Complication Refresh Intent
/// Intent to manually refresh all complications
@available(watchOS 10.0, *)
struct RefreshComplicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Complications"
    static var description = IntentDescription("Refreshes all watch complications to show the latest data.")

    @MainActor
    func perform() async -> some IntentResult {
        // Reload all complication timelines
        WidgetCenter.shared.reloadAllTimelines()

        return .result(
            dialog: "Complications refreshed"
        )
    }
}

// MARK: - App Shortcuts
/// App shortcuts for quick access from the watch face
@available(watchOS 10.0, *)
struct StressMonitorAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenWatchAppIntent(),
            phrases: [
                "View stress with \(.applicationName)",
                "Check stress level on \(.applicationName)",
                "Open \(.applicationName) stress"
            ],
            shortTitle: "View Stress",
            systemImageName: "heart.fill"
        )

        AppShortcut(
            intent: RefreshComplicationsIntent(),
            phrases: [
                "Refresh complications with \(.applicationName)"
            ],
            shortTitle: "Refresh",
            systemImageName: "arrow.clockwise"
        )
    }
}
