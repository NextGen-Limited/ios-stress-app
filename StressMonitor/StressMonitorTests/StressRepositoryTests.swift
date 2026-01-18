import XCTest
import SwiftData
@testable import StressMonitor

@MainActor
final class StressRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var repository: StressRepository!
    var modelContext: ModelContext!

    override func setUp() async throws {
        let schema = Schema([StressMeasurement.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
        repository = StressRepository(modelContext: modelContext)
    }

    override func tearDown() async throws {
        container = nil
        repository = nil
        modelContext = nil
    }

    // MARK: - save Tests

    func testSaveMeasurement() async throws {
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 45,
            hrv: 50,
            heartRate: 70,
            category: .mild
        )

        try await repository.save(measurement)

        let fetched = try await repository.fetchRecent(limit: 1)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.stressLevel, 45)
    }

    // MARK: - fetchRecent Tests

    func testFetchRecentReturnsEmpty() async throws {
        let fetched = try await repository.fetchRecent(limit: 5)
        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchRecentWithLimit() async throws {
        for i in 0..<10 {
            let measurement = StressMeasurement(
                timestamp: Date().addingTimeInterval(Double(i) * 60),
                stressLevel: Double(i * 10),
                hrv: 50,
                heartRate: 70,
                category: .mild
            )
            try await repository.save(measurement)
        }

        let fetched = try await repository.fetchRecent(limit: 5)
        XCTAssertEqual(fetched.count, 5)
    }

    func testFetchRecentOrdersByTimestampDescending() async throws {
        let dates = [
            Date().addingTimeInterval(-300),
            Date().addingTimeInterval(-100),
            Date()
        ]

        for (index, date) in dates.enumerated() {
            let measurement = StressMeasurement(
                timestamp: date,
                stressLevel: Double(index * 10),
                hrv: 50,
                heartRate: 70,
                category: .mild
            )
            try await repository.save(measurement)
        }

        let fetched = try await repository.fetchRecent(limit: 3)

        XCTAssertEqual(fetched[0].timestamp, dates[2])
        XCTAssertEqual(fetched[1].timestamp, dates[1])
        XCTAssertEqual(fetched[2].timestamp, dates[0])
    }

    // MARK: - fetchAll Tests

    func testFetchAll() async throws {
        for i in 0..<5 {
            let measurement = StressMeasurement(
                timestamp: Date(),
                stressLevel: Double(i * 10),
                hrv: 50,
                heartRate: 70,
                category: .mild
            )
            try await repository.save(measurement)
        }

        let fetched = try await repository.fetchAll()
        XCTAssertEqual(fetched.count, 5)
    }

    // MARK: - deleteOlderThan Tests

    func testDeleteOlderThan() async throws {
        let now = Date()

        let oldMeasurement = StressMeasurement(
            timestamp: now.addingTimeInterval(-86400 * 10),
            stressLevel: 30,
            hrv: 50,
            heartRate: 70,
            category: .relaxed
        )

        let newMeasurement = StressMeasurement(
            timestamp: now.addingTimeInterval(-86400),
            stressLevel: 60,
            hrv: 50,
            heartRate: 70,
            category: .moderate
        )

        try await repository.save(oldMeasurement)
        try await repository.save(newMeasurement)

        try await repository.deleteOlderThan(now.addingTimeInterval(-86400 * 5))

        let remaining = try await repository.fetchAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.stressLevel, 60)
    }

    // MARK: - getBaseline Tests

    func testGetBaselineWithNoData() async throws {
        let baseline = try await repository.getBaseline()

        XCTAssertEqual(baseline.baselineHRV, 50)
        XCTAssertEqual(baseline.restingHeartRate, 60)
    }

    func testGetBaselineCachesResult() async throws {
        let baseline1 = try await repository.getBaseline()
        let baseline2 = try await repository.getBaseline()

        XCTAssertTrue(baseline1.lastUpdated == baseline2.lastUpdated)
    }

    func testUpdateBaseline() async throws {
        let newBaseline = PersonalBaseline(
            restingHeartRate: 55,
            baselineHRV: 45,
            lastUpdated: Date()
        )

        try await repository.updateBaseline(newBaseline)

        let fetched = try await repository.getBaseline()

        XCTAssertEqual(fetched.restingHeartRate, 55)
        XCTAssertEqual(fetched.baselineHRV, 45)
    }
}
