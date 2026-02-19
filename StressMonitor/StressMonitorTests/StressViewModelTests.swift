import XCTest
import SwiftData
@testable import StressMonitor

@MainActor
final class StressViewModelTests: XCTestCase {

    var viewModel: StressViewModel!
    var mockHealthKit: MockHealthKitService!
    var mockAlgorithm: MockStressAlgorithmService!
    var mockRepository: MockStressViewModelRepository!

    override func setUp() async throws {
        mockHealthKit = MockHealthKitService()
        mockAlgorithm = MockStressAlgorithmService()
        mockRepository = MockStressViewModelRepository()

        viewModel = StressViewModel(
            healthKit: mockHealthKit,
            algorithm: mockAlgorithm,
            repository: mockRepository
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockHealthKit = nil
        mockAlgorithm = nil
        mockRepository = nil
    }

    // MARK: - loadCurrentStress Tests

    func testLoadCurrentStressSuccess() async throws {
        mockHealthKit.hrvToReturn = HRVMeasurement(value: 50)
        mockHealthKit.heartRatesToReturn = [HeartRateSample(value: 70)]
        mockAlgorithm.stressToReturn = StressResult(
            level: 30,
            category: .mild,
            confidence: 0.9,
            hrv: 50,
            heartRate: 70
        )

        await viewModel.loadCurrentStress()

        XCTAssertNotNil(viewModel.currentStress)
        XCTAssertEqual(viewModel.currentStress?.level, 30)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.lastRefresh)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadCurrentStressNoHRVData() async {
        mockHealthKit.hrvToReturn = nil

        await viewModel.loadCurrentStress()

        XCTAssertNil(viewModel.currentStress)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadCurrentStressSetsLoadingState() async {
        mockHealthKit.hrvToReturn = HRVMeasurement(value: 50)
        mockHealthKit.heartRatesToReturn = [HeartRateSample(value: 70)]
        mockAlgorithm.stressToReturn = StressResult(
            level: 30,
            category: .mild,
            confidence: 0.9,
            hrv: 50,
            heartRate: 70
        )

        // Verify initial state
        XCTAssertFalse(viewModel.isLoading, "Initial state should not be loading")

        // Run the operation
        await viewModel.loadCurrentStress()

        // Verify final state is not loading (important invariant)
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after operation completes")
    }

    // MARK: - loadHistoricalData Tests

    func testLoadHistoricalData() async throws {
        let measurements = [
            StressMeasurement(timestamp: Date(), stressLevel: 30, hrv: 50, restingHeartRate: 70),
            StressMeasurement(timestamp: Date(), stressLevel: 50, hrv: 45, restingHeartRate: 80)
        ]
        mockRepository.measurementsToReturn = measurements

        await viewModel.loadHistoricalData(days: 7)

        XCTAssertEqual(viewModel.historicalData.count, 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - loadBaseline Tests

    func testLoadBaseline() async throws {
        let baseline = PersonalBaseline(restingHeartRate: 55, baselineHRV: 48)
        mockRepository.baselineToReturn = baseline

        await viewModel.loadBaseline()

        XCTAssertEqual(viewModel.baseline?.restingHeartRate, 55)
        XCTAssertEqual(viewModel.baseline?.baselineHRV, 48)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - clearError Tests

    func testClearError() {
        viewModel.errorMessage = "Test error"
        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - calculateAndSaveStress Tests

    func testCalculateAndSaveStress() async throws {
        mockHealthKit.hrvToReturn = HRVMeasurement(value: 50)
        mockHealthKit.heartRatesToReturn = [HeartRateSample(value: 70)]
        mockAlgorithm.stressToReturn = StressResult(
            level: 30,
            category: .mild,
            confidence: 0.9,
            hrv: 50,
            heartRate: 70
        )

        try await viewModel.calculateAndSaveStress()

        XCTAssertNotNil(viewModel.currentStress)
        XCTAssertTrue(mockRepository.saveWasCalled)
    }
}

// MARK: - Mocks

final class MockHealthKitService: HealthKitServiceProtocol {
    var hrvToReturn: HRVMeasurement?
    var heartRatesToReturn: [HeartRateSample] = []

    func requestAuthorization() async throws {
    }

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        hrvToReturn
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        heartRatesToReturn
    }

    func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement] {
        []
    }

    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
        AsyncStream { _ in }
    }
}

final class MockStressAlgorithmService: StressAlgorithmServiceProtocol {
    var stressToReturn: StressResult?

    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        stressToReturn ?? StressResult(level: 0, category: .relaxed, confidence: 1, hrv: hrv, heartRate: heartRate)
    }

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        1.0
    }
}

final class MockStressViewModelRepository: StressRepositoryProtocol {
    var measurementsToReturn: [StressMeasurement] = []
    var baselineToReturn: PersonalBaseline?
    var saveWasCalled = false

    func save(_ measurement: StressMeasurement) async throws {
        saveWasCalled = true
    }

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        measurementsToReturn
    }

    func fetchAll() async throws -> [StressMeasurement] {
        measurementsToReturn
    }

    func deleteOlderThan(_ date: Date) async throws {
    }

    func getBaseline() async throws -> PersonalBaseline {
        baselineToReturn ?? PersonalBaseline()
    }

    func updateBaseline(_ baseline: PersonalBaseline) async throws {
    }

    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement] {
        return measurementsToReturn
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
