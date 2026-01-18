import Foundation
import Testing
import HealthKit
@testable import StressMonitor

struct HealthKitManagerTests {

    @Test func testHealthKitManager_initialization() async {
        let manager = await HealthKitManager()
        #expect(manager != nil)
    }

    @Test func testHealthKitManager_customHealthStore() async {
        let customStore = HKHealthStore()
        let manager = await HealthKitManager(healthStore: customStore)
        #expect(manager != nil)
    }
}
