import AppIntents
import WidgetKit

/// AppIntent for immediately updating the widget after a new measurement
/// This allows users to refresh widget content on-demand
@available(iOS 17.0, *)
public struct UpdateWidgetIntent: AppIntent {

    public init() {}

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
public enum UpdateStressWidgetShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: UpdateWidgetIntent(),
            phrases: [
                "Update \(.applicationName) stress widget",
                "Refresh \(.applicationName) stress widget",
                "Reload \(.applicationName) stress widget"
            ],
            shortTitle: "Update Widget",
            systemImageName: "arrow.clockwise"
        )
    }
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
    public func getConfiguredWidgets() async throws -> [WidgetInfo] {
        return try await WidgetCenter.shared.currentConfigurations()
    }
}
