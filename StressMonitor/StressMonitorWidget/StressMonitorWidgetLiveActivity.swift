//
//  StressMonitorWidgetLiveActivity.swift
//  StressMonitorWidget
//
//  Created by Phuong Doan Duy on 10/6/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StressMonitorWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StressMonitorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StressMonitorWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StressMonitorWidgetAttributes {
    fileprivate static var preview: StressMonitorWidgetAttributes {
        StressMonitorWidgetAttributes(name: "World")
    }
}

extension StressMonitorWidgetAttributes.ContentState {
    fileprivate static var smiley: StressMonitorWidgetAttributes.ContentState {
        StressMonitorWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StressMonitorWidgetAttributes.ContentState {
         StressMonitorWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StressMonitorWidgetAttributes.preview) {
   StressMonitorWidgetLiveActivity()
} contentStates: {
    StressMonitorWidgetAttributes.ContentState.smiley
    StressMonitorWidgetAttributes.ContentState.starEyes
}
