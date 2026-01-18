//
//  Item.swift
//  StressMonitor
//
//  Created by Phuong Doan Duy on 18/1/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
