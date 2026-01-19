import XCTest
import HealthKit
@testable import StressMonitor

@MainActor
final class OnboardingHealthSyncViewModelTests: XCTestCase {
    var viewModel: OnboardingHealthSyncViewModel!
    var mockHealthKitService: MockOnboardingHealthKitService!

    override func setUp() {
        super.setUp()
        mockHealthKitService = MockOnboardingHealthKitService()
        viewModel = OnboardingHealthSyncViewModel(healthKitService: mockHealthKitService)
    }

    override func tearDown() {
        viewModel = nil
        mockHealthKitService = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.healthKitAuthorized, "Should not be authorized initially")
        XCTAssertNil(viewModel.authorizationError, "Should not have error initially")
        XCTAssertFalse(viewModel.canProceed, "Should not be able to proceed without authorization")
    }

    func testSuccessfulAuthorization() async {
        mockHealthKitService.shouldSucceed = true

        await viewModel.requestHealthKitAuthorization()

        XCTAssertTrue(viewModel.healthKitAuthorized, "Should be authorized after successful request")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after request completes")
        XCTAssertNil(viewModel.authorizationError, "Should not have error on success")
        XCTAssertTrue(viewModel.canProceed, "Should be able to proceed after authorization")
    }

    func testFailedAuthorization() async {
        mockHealthKitService.shouldSucceed = false
        mockHealthKitService.errorToThrow = OnboardingHealthKitError.notAvailable

        await viewModel.requestHealthKitAuthorization()

        XCTAssertFalse(viewModel.healthKitAuthorized, "Should not be authorized after failed request")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after request completes")
        XCTAssertNotNil(viewModel.authorizationError, "Should have error message on failure")
        XCTAssertFalse(viewModel.canProceed, "Should not be able to proceed without authorization")
    }

    func testLoadingStateClearedAfterAuthorization() async {
        mockHealthKitService.shouldSucceed = true

        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")

        await viewModel.requestHealthKitAuthorization()

        XCTAssertFalse(viewModel.isLoading, "Should not be loading after authorization completes")
    }
}

// Mock HealthKit Service for onboarding tests
final class MockOnboardingHealthKitService: HealthKitServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: Error?

    func requestAuthorization() async throws {
        if !shouldSucceed {
            throw errorToThrow ?? NSError(domain: "TestError", code: -1)
        }
    }

    nonisolated func fetchLatestHRV() async throws -> HRVMeasurement? {
        return nil
    }

    nonisolated func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        return []
    }

    nonisolated func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement] {
        return []
    }

    nonisolated func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
        return AsyncStream { _ in }
    }
}

enum OnboardingHealthKitError: Error {
    case notAvailable
}
