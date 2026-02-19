import XCTest
@testable import StressMonitor

@MainActor
final class OnboardingBaselineCalibrationViewModelTests: XCTestCase {
    var viewModel: OnboardingBaselineCalibrationViewModel!
    var mockRepository: MockBaselineRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockBaselineRepository()
        viewModel = OnboardingBaselineCalibrationViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        UserDefaults.standard.removeObject(forKey: "calibrationDay")
        UserDefaults.standard.removeObject(forKey: "calibrationCompleted")
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.currentDay, 1, "Should start on day 1")
        XCTAssertFalse(viewModel.calibrationCompleted, "Should not be completed initially")
        XCTAssertFalse(viewModel.dailyMeasurementTaken, "Should not have measurement taken initially")
    }

    func testStartCalibration() {
        viewModel.currentDay = 5
        viewModel.dailyMeasurementTaken = true

        viewModel.startCalibration()

        XCTAssertEqual(viewModel.currentDay, 1, "Should reset to day 1")
        XCTAssertFalse(viewModel.dailyMeasurementTaken, "Should reset measurement status")
        XCTAssertFalse(viewModel.calibrationCompleted, "Should not be completed")
    }

    func testRecordDailyMeasurement() async {
        viewModel.currentDay = 1

        await viewModel.recordDailyMeasurement()

        // After recording, day advances and measurement resets for next day
        XCTAssertEqual(viewModel.currentDay, 2, "Should advance to next day")
        XCTAssertFalse(viewModel.dailyMeasurementTaken, "Should reset for next day")
    }

    func testRecordFinalDayMeasurement() async {
        viewModel.currentDay = 7

        await viewModel.recordDailyMeasurement()

        XCTAssertTrue(viewModel.calibrationCompleted, "Should be completed after day 7")
    }

    func testCalibrationPhases() {
        viewModel.currentDay = 1
        XCTAssertEqual(viewModel.currentPhase, .learning, "Day 1 should be learning phase")

        viewModel.currentDay = 2
        XCTAssertEqual(viewModel.currentPhase, .learning, "Day 2 should be learning phase")

        viewModel.currentDay = 4
        XCTAssertEqual(viewModel.currentPhase, .calibration, "Day 4 should be calibration phase")

        viewModel.currentDay = 6
        XCTAssertEqual(viewModel.currentPhase, .validation, "Day 6 should be validation phase")

        viewModel.currentDay = 8
        XCTAssertEqual(viewModel.currentPhase, .complete, "Day 8 should be complete phase")
    }

    func testCompleteCalibration() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "baselineCalibrated"))

        viewModel.completeCalibration()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "baselineCalibrated"))
    }

    func testPersistCalibrationState() {
        viewModel.currentDay = 3
        viewModel.startCalibration()

        let persistedDay = UserDefaults.standard.integer(forKey: "calibrationDay")
        XCTAssertEqual(persistedDay, 1, "Should persist calibration state when starting")
    }
}

// Mock Repository for baseline calibration tests
final class MockBaselineRepository: StressRepositoryProtocol {
    func save(_ measurement: StressMeasurement) async throws {}

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        return []
    }

    func fetchAll() async throws -> [StressMeasurement] {
        return []
    }

    func deleteOlderThan(_ date: Date) async throws {}

    func getBaseline() async throws -> PersonalBaseline {
        return PersonalBaseline()
    }

    func updateBaseline(_ baseline: PersonalBaseline) async throws {}

    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement] {
        return []
    }

    func delete(_ measurement: StressMeasurement) async throws {}

    func fetchAverageHRV(hours: Int) async throws -> Double {
        return 0.0
    }

    func fetchAverageHRV(days: Int) async throws -> Double {
        return 0.0
    }

    func deleteAllMeasurements() async throws {}
}
