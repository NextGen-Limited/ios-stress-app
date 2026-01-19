import XCTest
@testable import StressMonitor

@MainActor
final class OnboardingWelcomeViewModelTests: XCTestCase {
    var viewModel: OnboardingWelcomeViewModel!

    override func setUp() {
        super.setUp()
        viewModel = OnboardingWelcomeViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.isAnimating, "Animation should start as true")
        XCTAssertFalse(viewModel.navigateToHealthKit, "Should not navigate to HealthKit initially")
        XCTAssertFalse(viewModel.navigateToSignIn, "Should not navigate to sign in initially")
    }

    func testHandleGetStarted() {
        viewModel.handleGetStarted()

        XCTAssertTrue(viewModel.navigateToHealthKit, "Should navigate to HealthKit after get started")
        XCTAssertFalse(viewModel.navigateToSignIn, "Should not navigate to sign in")
    }

    func testHandleSignIn() {
        viewModel.handleSignIn()

        XCTAssertTrue(viewModel.navigateToSignIn, "Should navigate to sign in")
        XCTAssertFalse(viewModel.navigateToHealthKit, "Should not navigate to HealthKit")
    }

    func testAnimationState() {
        let initialAnimationState = viewModel.isAnimating

        viewModel.handleGetStarted()

        XCTAssertEqual(viewModel.isAnimating, initialAnimationState, "Animation state should not change on navigation")
    }
}
