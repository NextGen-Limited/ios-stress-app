import XCTest
@testable import StressMonitor

@MainActor
final class OnboardingSuccessViewModelTests: XCTestCase {
    var viewModel: OnboardingSuccessViewModel!
    var mockRepository: MockSuccessRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockSuccessRepository()
        viewModel = OnboardingSuccessViewModel(repository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertNil(viewModel.personalBaseline, "Baseline should be nil initially")
    }

    func testLoadBaseline() async {
        mockRepository.baselineToReturn = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50, lastUpdated: Date())

        viewModel.loadBaseline()

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        XCTAssertNotNil(viewModel.personalBaseline, "Should load baseline")
        XCTAssertEqual(viewModel.personalBaseline?.restingHeartRate, 60)
        XCTAssertEqual(viewModel.personalBaseline?.baselineHRV, 50)
    }

    func testCompleteOnboarding() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))

        viewModel.completeOnboarding()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    func testCompleteOnboardingPersists() {
        viewModel.completeOnboarding()

        let flag = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        XCTAssertTrue(flag, "Onboarding completion flag should persist")
    }
}

// Mock Repository for success view tests
final class MockSuccessRepository: StressRepositoryProtocol {
    var baselineToReturn: PersonalBaseline?

    func save(_ measurement: StressMeasurement) async throws {}

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        return []
    }

    func fetchAll() async throws -> [StressMeasurement] {
        return []
    }

    func deleteOlderThan(_ date: Date) async throws {}

    func getBaseline() async throws -> PersonalBaseline {
        if let baseline = baselineToReturn {
            return baseline
        }
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
