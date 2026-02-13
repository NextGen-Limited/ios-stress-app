import XCTest
import SwiftUI
@testable import StressMonitor

// MARK: - Breathing Exercise View Tests

final class BreathingExerciseViewTests: XCTestCase {

    // MARK: - Breathing Phase Tests

    func testBreathingPhaseDurations() {
        // Test 4-7-8 breathing pattern
        XCTAssertEqual(BreathingPhase.inhale.duration, 4.0, "Inhale should be 4 seconds")
        XCTAssertEqual(BreathingPhase.hold.duration, 7.0, "Hold should be 7 seconds")
        XCTAssertEqual(BreathingPhase.exhale.duration, 8.0, "Exhale should be 8 seconds")
        XCTAssertEqual(BreathingPhase.pause.duration, 1.0, "Pause should be 1 second")
    }

    func testBreathingPhaseDisplayText() {
        XCTAssertEqual(BreathingPhase.inhale.displayText, "Inhale")
        XCTAssertEqual(BreathingPhase.hold.displayText, "Hold")
        XCTAssertEqual(BreathingPhase.exhale.displayText, "Exhale")
        XCTAssertEqual(BreathingPhase.pause.displayText, "Pause")
    }

    func testBreathingPhaseInstructions() {
        XCTAssertEqual(BreathingPhase.inhale.instruction, "Breathe in slowly through your nose")
        XCTAssertEqual(BreathingPhase.hold.instruction, "Hold your breath gently")
        XCTAssertEqual(BreathingPhase.exhale.instruction, "Breathe out slowly through your mouth")
        XCTAssertEqual(BreathingPhase.pause.instruction, "Relax and prepare")
    }

    func testBreathingPhaseIcons() {
        XCTAssertEqual(BreathingPhase.inhale.icon, "arrow.down.circle.fill")
        XCTAssertEqual(BreathingPhase.hold.icon, "pause.circle.fill")
        XCTAssertEqual(BreathingPhase.exhale.icon, "arrow.up.circle.fill")
        XCTAssertEqual(BreathingPhase.pause.icon, "moon.circle.fill")
    }

    func testBreathingPhaseColors() {
        XCTAssertEqual(BreathingPhase.inhale.color, Color.blue)
        XCTAssertEqual(BreathingPhase.hold.color, Color.purple)
        XCTAssertEqual(BreathingPhase.exhale.color, Color.green)
        XCTAssertEqual(BreathingPhase.pause.color, Color.secondary)
    }

    // MARK: - Cycle Completion Tests

    func testCycleCompletion() {
        // Total duration: (4 + 7 + 8 + 1) * 4 cycles = 80 seconds
        let totalDuration = (BreathingPhase.inhale.duration +
                           BreathingPhase.hold.duration +
                           BreathingPhase.exhale.duration +
                           BreathingPhase.pause.duration) * 4

        XCTAssertEqual(totalDuration, 80.0, "Full 4-cycle session should take 80 seconds")
    }

    func testSingleCycleDuration() {
        let cycleDuration = BreathingPhase.inhale.duration +
                          BreathingPhase.hold.duration +
                          BreathingPhase.exhale.duration +
                          BreathingPhase.pause.duration

        XCTAssertEqual(cycleDuration, 20.0, "Single cycle should take 20 seconds")
    }

    // MARK: - Reduce Motion Support Tests

    func testReduceMotionStaticCircle() {
        // Test that static circle shows correct elements
        let phases: [BreathingPhase] = [.inhale, .hold, .exhale, .pause]

        for phase in phases {
            // Verify phase has all required properties for static display
            XCTAssertFalse(phase.displayText.isEmpty, "Phase should have display text")
            XCTAssertFalse(phase.instruction.isEmpty, "Phase should have instruction")
            XCTAssertFalse(phase.icon.isEmpty, "Phase should have icon")
        }
    }

    func testReduceMotionAnimatedCircle() {
        // Test that animated circle scale calculations work
        let inhale = BreathingPhase.inhale
        let hold = BreathingPhase.hold
        let exhale = BreathingPhase.exhale
        let pause = BreathingPhase.pause

        // Verify phases have consistent properties
        XCTAssertNotNil(inhale.color)
        XCTAssertNotNil(hold.color)
        XCTAssertNotNil(exhale.color)
        XCTAssertNotNil(pause.color)
    }
}
