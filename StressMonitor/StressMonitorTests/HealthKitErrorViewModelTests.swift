import XCTest
@testable import StressMonitor

@MainActor
final class HealthKitErrorViewModelTests: XCTestCase {
    var viewModel: HealthKitErrorViewModel!

    override func setUp() {
        super.setUp()
        viewModel = HealthKitErrorViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testOpenSettingsURL() {
        // Test that the method doesn't crash
        XCTAssertNoThrow(viewModel.openSettings(), "Should not throw when opening settings")
    }

    func testDismissToWelcome() {
        // Test that the method doesn't crash
        XCTAssertNoThrow(viewModel.dismissToWelcome(), "Should not throw when dismissing")
    }
}
