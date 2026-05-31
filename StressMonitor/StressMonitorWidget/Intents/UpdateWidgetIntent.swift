import AppIntents
import WidgetKit

/// AppIntent for immediately updating the widget after a new measurement
/// This allows users to refresh widget content on-demand
@available(iOS 17.0, *)
public struct UpdateWidgetIntent: AppIntent {

    public static var title: LocalizedStringResource = "Update Widget"
    public static var description = IntentDescription("Refreshes the stress widget with the latest data.")

    // MARK: - Perform

    public func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()

        // Return success
        return .result(value: true)
    }
}

// MARK: - Update Widget Shortcuts

@available(iOS 17.0, *)
public struct UpdateStressWidgetShortcut: AppShortcut {

    public static var appItem: AppItem {
        AppItem(
            appName: "StressMonitor",
            appIdentifier: "com.stressmonitor.app"
        )
    }

    public static var phrases: [AppShortcutPhrase] {
        [
            .init(type: UpdateWidgetIntent.self(), phrases: [
                "Update stress widget",
                "Refresh stress widget",
                "Reload stress widget"
            ])
        ]
    }

    public static var shortTitle: LocalizedStringResource = "Update Widget"
    public static var systemImageName: String = "arrow.clockwise"
}

// MARK: - Helper for Main App

/// Helper class to update widget from main app
@available(iOS 17.0, *)
public final class WidgetUpdater {

    public static let shared = WidgetUpdater()

    private init() {}

    /// Call this after saving a new stress measurement
    public func widgetDidUpdate() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reload only specific widget kind
    public func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    /// Get all configured widgets
    public func getConfiguredWidgets() async -> [WidgetInfo] {
        return await WidgetCenter.shared.currentConfigurations
    }
}
