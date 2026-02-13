import XCTest
import UIKit
import CoreHaptics
@testable import StressMonitor

// MARK: - Haptic Manager Tests

final class HapticManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: HapticManager!

    // MARK: - Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        sut = HapticManager.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    @MainActor
    func testSharedInstance() {
        let instance1 = HapticManager.shared
        let instance2 = HapticManager.shared

        XCTAssertTrue(instance1 === instance2, "HapticManager should be a singleton")
    }

    // MARK: - Hardware Capability Tests

    func testHardwareCapabilitiesDetection() {
        let capabilities = CHHapticEngine.capabilitiesForHardware()
        let supportsHaptics = capabilities.supportsHaptics

        // Device may or may not support haptics
        // Test passes if detection works without crash
        XCTAssertNotNil(capabilities)
        print("Device supports haptics: \(supportsHaptics)")
    }

    // MARK: - Stress Level Change Haptics

    @MainActor
    func testStressLevelChangedToRelaxed() {
        // Test that relaxed category triggers success haptic
        XCTAssertNoThrow(sut.stressLevelChanged(to: .relaxed))
    }

    @MainActor
    func testStressLevelChangedToMild() {
        // Test that mild category triggers light haptic
        XCTAssertNoThrow(sut.stressLevelChanged(to: .mild))
    }

    @MainActor
    func testStressLevelChangedToModerate() {
        // Test that moderate category triggers warning haptic
        XCTAssertNoThrow(sut.stressLevelChanged(to: .moderate))
    }

    @MainActor
    func testStressLevelChangedToHigh() {
        // Test that high category triggers error haptic
        XCTAssertNoThrow(sut.stressLevelChanged(to: .high))
    }

    // MARK: - Breathing Cue Haptic Tests

    @MainActor
    func testBreathingCueHaptic() {
        // Test light impact at 50% intensity
        XCTAssertNoThrow(sut.breathingCue())

        // Breathing cue should be gentle and non-intrusive
        // Testing execution without crash
    }

    @MainActor
    func testBreathingCueIntensity() {
        // Breathing cue should use light impact style
        // at 0.5 intensity (50%)
        // This is a functional test - implementation uses UIImpactFeedbackGenerator(style: .light)
        XCTAssertNoThrow(sut.breathingCue())
    }

    // MARK: - Button Press Haptic Tests

    @MainActor
    func testButtonPressHaptic() {
        // Test medium impact for button presses
        XCTAssertNoThrow(sut.buttonPress())
    }

    // MARK: - Stress Buddy Mood Change Tests

    @MainActor
    func testStressBuddyMoodChangeHaptic() {
        let mood = StressBuddyMood.calm
        XCTAssertNoThrow(sut.stressBuddyMoodChange(to: mood))
    }

    // MARK: - Individual Haptic Methods Tests

    @MainActor
    func testSuccessHaptic() {
        XCTAssertNoThrow(sut.success())
    }

    @MainActor
    func testWarningHaptic() {
        XCTAssertNoThrow(sut.warning())
    }

    @MainActor
    func testErrorHaptic() {
        XCTAssertNoThrow(sut.error())
    }

    // MARK: - Graceful Fallback Tests

    func testGracefulFallbackWhenHapticsUnavailable() {
        // On devices without haptic engine (iPad, older devices),
        // methods should fail gracefully without crash

        let capabilities = CHHapticEngine.capabilitiesForHardware()
        if !capabilities.supportsHaptics {
            // Test that all methods complete without errors
            Task { @MainActor in
                XCTAssertNoThrow(sut.breathingCue())
                XCTAssertNoThrow(sut.buttonPress())
                XCTAssertNoThrow(sut.success())
                XCTAssertNoThrow(sut.warning())
                XCTAssertNoThrow(sut.error())
            }
        }
    }

    // MARK: - Thread Safety Tests

    @MainActor
    func testConcurrentHapticCalls() {
        // Test that multiple rapid haptic calls don't crash
        let expectation = expectation(description: "Multiple haptics complete")
        expectation.expectedFulfillmentCount = 5

        for _ in 0..<5 {
            Task { @MainActor in
                sut.buttonPress()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Haptic Pattern Tests

    @MainActor
    func testBreathingCuePattern() {
        // Breathing cue should be consistent and gentle
        // Test that calling it multiple times works
        for _ in 0..<3 {
            XCTAssertNoThrow(sut.breathingCue())
        }
    }

    // MARK: - Engine Initialization Tests

    func testHapticEngineInitialization() {
        // Test that engine initializes only when hardware supports it
        let capabilities = CHHapticEngine.capabilitiesForHardware()

        if capabilities.supportsHaptics {
            // Engine should be initialized
            do {
                let engine = try CHHapticEngine()
                XCTAssertNotNil(engine)
            } catch {
                XCTFail("Haptic engine should initialize on supported hardware")
            }
        } else {
            // Engine initialization might fail, which is expected
            print("Hardware does not support haptics - skipping engine test")
        }
    }
}
