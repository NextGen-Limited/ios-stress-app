import Foundation
import SwiftData

// MARK: - Mock HealthKit Service

/// Mock HealthKit service for SwiftUI previews and testing
final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    var mockHRV: Double = 50.0
    var mockHeartRate: Double = 72.0
    var mockHRVHistory: [HRVMeasurement] = []
    var shouldThrowError: Bool = false

    func requestAuthorization() async throws {
        if shouldThrowError { throw NSError(domain: "Mock", code: -1) }
    }

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        if shouldThrowError { throw NSError(domain: "Mock", code: -1) }
        return HRVMeasurement(value: mockHRV, timestamp: Date())
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        if shouldThrowError { throw NSError(domain: "Mock", code: -1) }
        return [HeartRateSample(value: mockHeartRate, timestamp: Date())]
    }

    func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement] {
        if shouldThrowError { throw NSError(domain: "Mock", code: -1) }
        return mockHRVHistory.isEmpty
            ? [HRVMeasurement(value: mockHRV, timestamp: Date())]
            : mockHRVHistory
    }

    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
        AsyncStream { continuation in
            continuation.yield(HeartRateSample(value: mockHeartRate, timestamp: Date()))
            continuation.finish()
        }
    }
}

// MARK: - Mock Algorithm Service

/// Mock stress algorithm service for SwiftUI previews
final class MockStressAlgorithmService: StressAlgorithmServiceProtocol, @unchecked Sendable {
    var mockStressLevel: Double = 35.0
    var mockConfidence: Double = 0.85

    func calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult {
        StressResult(
            level: mockStressLevel,
            category: StressCategory(from: mockStressLevel),
            confidence: mockConfidence,
            hrv: hrv,
            heartRate: heartRate,
            timestamp: Date()
        )
    }

    func calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double {
        mockConfidence
    }
}

// MARK: - Mock Repository Service

/// Mock stress repository for SwiftUI previews
/// Note: @MainActor provides implicit Sendable conformance
@MainActor
final class MockStressRepository: StressRepositoryProtocol {
    var mockMeasurements: [StressMeasurement] = []
    var mockBaseline: PersonalBaseline = PersonalBaseline(restingHeartRate: 65, baselineHRV: 50)

    func save(_ measurement: StressMeasurement) async throws {
        mockMeasurements.append(measurement)
    }

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        Array(mockMeasurements.prefix(limit))
    }

    func fetchAll() async throws -> [StressMeasurement] {
        mockMeasurements
    }

    func deleteOlderThan(_ date: Date) async throws {}

    func getBaseline() async throws -> PersonalBaseline {
        mockBaseline
    }

    func updateBaseline(_ baseline: PersonalBaseline) async throws {
        mockBaseline = baseline
    }

    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement] {
        mockMeasurements.filter { $0.timestamp >= from && $0.timestamp <= to }
    }

    func delete(_ measurement: StressMeasurement) async throws {
        mockMeasurements.removeAll { $0.id == measurement.id }
    }

    func fetchAverageHRV(hours: Int) async throws -> Double {
        mockBaseline.baselineHRV
    }

    func fetchAverageHRV(days: Int) async throws -> Double {
        mockBaseline.baselineHRV
    }

    func deleteAllMeasurements() async throws {
        mockMeasurements.removeAll()
    }
}

// MARK: - Preview Data Factory

/// Factory for creating preview data for SwiftUI previews
enum PreviewDataFactory {

    // MARK: Stress Results

    /// Relaxed stress result (0-25 range)
    static func relaxedStress() -> StressResult {
        StressResult(level: 15, category: .relaxed, confidence: 0.92, hrv: 65, heartRate: 58)
    }

    /// Mild stress result (25-50 range)
    static func mildStress() -> StressResult {
        StressResult(level: 38, category: .mild, confidence: 0.85, hrv: 45, heartRate: 72)
    }

    /// Moderate stress result (50-75 range)
    static func moderateStress() -> StressResult {
        StressResult(level: 62, category: .moderate, confidence: 0.78, hrv: 32, heartRate: 85)
    }

    /// High stress result (75-100 range)
    static func highStress() -> StressResult {
        StressResult(level: 85, category: .high, confidence: 0.88, hrv: 22, heartRate: 98)
    }

    // MARK: Mock Services

    /// Mock HealthKit service with default preview data
    static func mockHealthKit(
        hrv: Double = 50,
        heartRate: Double = 72
    ) -> MockHealthKitService {
        let service = MockHealthKitService()
        service.mockHRV = hrv
        service.mockHeartRate = heartRate
        return service
    }

    /// Mock algorithm service with default preview data
    static func mockAlgorithm(
        stressLevel: Double = 35,
        confidence: Double = 0.85
    ) -> MockStressAlgorithmService {
        let service = MockStressAlgorithmService()
        service.mockStressLevel = stressLevel
        service.mockConfidence = confidence
        return service
    }

    /// Mock repository with pre-populated measurements
    static func mockRepository(
        measurements: [StressMeasurement] = []
    ) -> MockStressRepository {
        let repo = MockStressRepository()
        repo.mockMeasurements = measurements
        return repo
    }

    // MARK: Mock ViewModels

    /// StressViewModel configured for previews with mock services
    static func mockStressViewModel(
        stressResult: StressResult? = nil,
        liveHeartRate: Double? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) -> StressViewModel {
        let healthKit = mockHealthKit(
            hrv: stressResult?.hrv ?? 50,
            heartRate: stressResult?.heartRate ?? 72
        )
        let algorithm = mockAlgorithm(
            stressLevel: stressResult?.level ?? 35,
            confidence: stressResult?.confidence ?? 0.85
        )
        let repository = mockRepository()

        let viewModel = StressViewModel(
            healthKit: healthKit,
            algorithm: algorithm,
            repository: repository
        )

        // Set preview state directly
        viewModel.currentStress = stressResult
        viewModel.liveHeartRate = liveHeartRate
        viewModel.isLoading = isLoading
        viewModel.errorMessage = errorMessage

        return viewModel
    }
}

// MARK: - StressResult Preview Extensions

extension StressResult {
    /// Sample relaxed state for previews
    static var previewRelaxed: StressResult {
        PreviewDataFactory.relaxedStress()
    }

    /// Sample mild stress for previews
    static var previewMild: StressResult {
        PreviewDataFactory.mildStress()
    }

    /// Sample moderate stress for previews
    static var previewModerate: StressResult {
        PreviewDataFactory.moderateStress()
    }

    /// Sample high stress for previews
    static var previewHigh: StressResult {
        PreviewDataFactory.highStress()
    }
}
