import Foundation
import SwiftData
@testable import StressMonitor

@MainActor
struct TestDataFactory {

    static func createMeasurement(
        stressLevel: Double = 50,
        hrv: Double = 50,
        heartRate: Double = 60,
        daysAgo: Int = 0
    ) -> StressMeasurement {
        let timestamp = Date().addingTimeInterval(-Double(daysAgo * 86400))
        return StressMeasurement(
            timestamp: timestamp,
            stressLevel: stressLevel,
            hrv: hrv,
            restingHeartRate: heartRate,
            confidences: [0.8]
        )
    }

    static func createMeasurementBatch(
        count: Int,
        stressRange: ClosedRange<Double> = 20...80,
        hrvRange: ClosedRange<Double> = 30...70,
        startDaysAgo: Int = 0
    ) -> [StressMeasurement] {
        (0..<count).map { index in
            let stress = Double.random(in: stressRange)
            let hrv = Double.random(in: hrvRange)
            let heartRate = Double.random(in: 50...90)
            return createMeasurement(
                stressLevel: stress,
                hrv: hrv,
                heartRate: heartRate,
                daysAgo: startDaysAgo + index
            )
        }
    }

    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([StressMeasurement.self, PersonalBaseline.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
