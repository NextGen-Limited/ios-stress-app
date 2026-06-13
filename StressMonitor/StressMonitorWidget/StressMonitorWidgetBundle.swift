import WidgetKit
import SwiftUI

@main
struct StressMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        StressMonitorWidget()
        LockScreenStressWidget()
        StressMonitorWidgetControl()
        StressMonitorWidgetLiveActivity()
    }
}
