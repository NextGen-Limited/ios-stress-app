import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Stress Check Control Widget

/// Control Center widget that shows the current Ripple character face.
/// Tapping opens StressMonitor for a fresh reading.
@available(iOS 17.0, *)
struct StressMonitorWidgetControl: ControlWidget {
    static let kind: String = "stress.ai.com.StressMonitorControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: OpenStressMonitorIntent()) {
                Label("Check Stress", systemImage: "heart.text.squarefill")
            }
        }
        .displayName("Ripple Check")
        .description("Tap to measure your stress level.")
    }
}

// MARK: - Open App Intent

struct OpenStressMonitorIntent: AppIntent {
    static let title: LocalizedStringResource = "Open StressMonitor"
    static let description = IntentDescription("Opens StressMonitor to take a stress measurement.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
