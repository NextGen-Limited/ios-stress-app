//
//  StressMonitorWidgetBundle.swift
//  StressMonitorWidget
//
//  Created by Phuong Doan Duy on 10/6/26.
//

import WidgetKit
import SwiftUI

@main
struct StressMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        StressMonitorWidget()
        StressMonitorWidgetControl()
        StressMonitorWidgetLiveActivity()
    }
}
