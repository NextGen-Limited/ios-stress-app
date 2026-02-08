import WidgetKit
import SwiftUI

// MARK: - Complication Bundle
/// WidgetKit bundle configuration for watchOS complications
/// Manages all complication families: Circular, Rectangular, and Inline
struct ComplicationBundle: WidgetBundle {
    var body: some Widget {
        CircularComplication()
        RectangularComplication()
        InlineComplication()
    }
}

// MARK: - Widget Configuration
extension ComplicationBundle {
    /// Supported complication families for watchOS 10+
    static var supportedFamilies: [WidgetFamily] {
        if #available(watchOS 10.0, *) {
            return [
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
            ]
        } else {
            return []
        }
    }
}

// MARK: - Timeline Update Policy
extension ComplicationBundle {
    /// WidgetKit timeline refresh policy
    /// Complications update every 15-30 minutes to stay within budget
    static var timelinePolicy: TimelineReloadPolicy {
        .atEnd
    }
}
