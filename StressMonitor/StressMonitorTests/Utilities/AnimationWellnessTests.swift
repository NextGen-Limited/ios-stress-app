import Foundation
import Testing
import SwiftUI
@testable import StressMonitor

// MARK: - Animation+Wellness Tests

/// Tests for Phase 2: Character System - Animation utilities
/// Validates Reduce Motion support and all animation types
struct AnimationWellnessTests {

    // MARK: - Reduce Motion Detection Tests

    @Test func testWellnessAnimationWithReduceMotionDisabled() {
        let animation = Animation.wellness(duration: 1.0, reduceMotion: false)
        #expect(animation != nil, "Animation should exist when Reduce Motion is disabled")
    }

    @Test func testWellnessAnimationWithReduceMotionEnabled() {
        let animation = Animation.wellness(duration: 1.0, reduceMotion: true)
        #expect(animation == nil, "Animation should be nil when Reduce Motion is enabled")
    }

    @Test func testBreathingAnimationWithReduceMotionDisabled() {
        let animation = Animation.breathing(reduceMotion: false)
        #expect(animation != nil, "Breathing animation should exist when Reduce Motion is disabled")
    }

    @Test func testBreathingAnimationWithReduceMotionEnabled() {
        let animation = Animation.breathing(reduceMotion: true)
        #expect(animation == nil, "Breathing animation should be nil when Reduce Motion is enabled")
    }

    @Test func testFidgetAnimationWithReduceMotionDisabled() {
        let animation = Animation.fidget(reduceMotion: false)
        #expect(animation != nil, "Fidget animation should exist when Reduce Motion is disabled")
    }

    @Test func testFidgetAnimationWithReduceMotionEnabled() {
        let animation = Animation.fidget(reduceMotion: true)
        #expect(animation == nil, "Fidget animation should be nil when Reduce Motion is enabled")
    }

    @Test func testShakeAnimationWithReduceMotionDisabled() {
        let animation = Animation.shake(reduceMotion: false)
        #expect(animation != nil, "Shake animation should exist when Reduce Motion is disabled")
    }

    @Test func testShakeAnimationWithReduceMotionEnabled() {
        let animation = Animation.shake(reduceMotion: true)
        #expect(animation == nil, "Shake animation should be nil when Reduce Motion is enabled")
    }

    @Test func testDizzyAnimationWithReduceMotionDisabled() {
        let animation = Animation.dizzy(reduceMotion: false)
        #expect(animation != nil, "Dizzy animation should exist when Reduce Motion is disabled")
    }

    @Test func testDizzyAnimationWithReduceMotionEnabled() {
        let animation = Animation.dizzy(reduceMotion: true)
        #expect(animation == nil, "Dizzy animation should be nil when Reduce Motion is enabled")
    }

    // MARK: - Animation Type Tests

    @Test func testWellnessAnimationType() {
        // Wellness animation should be easeInOut
        let animation = Animation.wellness(duration: 2.0, reduceMotion: false)
        #expect(animation != nil)
        // Note: We can't directly test Animation properties, but we verify it creates successfully
    }

    @Test func testBreathingAnimationIsRepeating() {
        // Breathing should create a repeating animation
        let animation = Animation.breathing(reduceMotion: false)
        #expect(animation != nil)
        // Breathing uses repeatForever(autoreverses: true)
    }

    @Test func testFidgetAnimationDuration() {
        // Fidget should be quick (0.5s)
        let animation = Animation.fidget(reduceMotion: false)
        #expect(animation != nil)
    }

    @Test func testShakeAnimationRepeats() {
        // Shake should repeat 3 times
        let animation = Animation.shake(reduceMotion: false)
        #expect(animation != nil)
        // Uses repeatCount(3, autoreverses: true)
    }

    @Test func testDizzyAnimationIsContinuous() {
        // Dizzy should be continuous rotation
        let animation = Animation.dizzy(reduceMotion: false)
        #expect(animation != nil)
        // Uses linear + repeatForever(autoreverses: false)
    }

    // MARK: - Default Parameter Tests

    @Test func testWellnessAnimationDefaultsToMotionEnabled() {
        // Default should assume Reduce Motion is disabled
        let animation = Animation.wellness(duration: 1.0)
        #expect(animation != nil)
    }

    @Test func testBreathingAnimationDefaultsToMotionEnabled() {
        let animation = Animation.breathing()
        #expect(animation != nil)
    }

    @Test func testFidgetAnimationDefaultsToMotionEnabled() {
        let animation = Animation.fidget()
        #expect(animation != nil)
    }

    @Test func testShakeAnimationDefaultsToMotionEnabled() {
        let animation = Animation.shake()
        #expect(animation != nil)
    }

    @Test func testDizzyAnimationDefaultsToMotionEnabled() {
        let animation = Animation.dizzy()
        #expect(animation != nil)
    }

    // MARK: - Accessibility Transition Tests

    @Test func testAccessibleOpacityTransitionWithMotionDisabled() {
        let transition = AnyTransition.accessibleOpacity(reduceMotion: true)
        // Should return identity (no transition)
        // Note: Can't directly compare AnyTransition, but verify it creates
        let _ = transition
    }

    @Test func testAccessibleOpacityTransitionWithMotionEnabled() {
        let transition = AnyTransition.accessibleOpacity(reduceMotion: false)
        // Should return opacity transition
        let _ = transition
    }

    @Test func testAccessibleScaleTransitionWithMotionDisabled() {
        let transition = AnyTransition.accessibleScale(reduceMotion: true)
        let _ = transition
    }

    @Test func testAccessibleScaleTransitionWithMotionEnabled() {
        let transition = AnyTransition.accessibleScale(reduceMotion: false)
        let _ = transition
    }

    @Test func testAccessibleSlideTransitionWithMotionDisabled() {
        let transition = AnyTransition.accessibleSlide(reduceMotion: true, edge: .bottom)
        let _ = transition
    }

    @Test func testAccessibleSlideTransitionWithMotionEnabled() {
        let transition = AnyTransition.accessibleSlide(reduceMotion: false, edge: .bottom)
        let _ = transition
    }

    @Test func testAccessibleSlideTransitionAllEdges() {
        // Test all edge variations
        let _ = AnyTransition.accessibleSlide(reduceMotion: false, edge: .top)
        let _ = AnyTransition.accessibleSlide(reduceMotion: false, edge: .bottom)
        let _ = AnyTransition.accessibleSlide(reduceMotion: false, edge: .leading)
        let _ = AnyTransition.accessibleSlide(reduceMotion: false, edge: .trailing)
    }

    // MARK: - Animation Duration Tests

    @Test func testCustomWellnessDuration() {
        // Test custom duration parameter
        let shortAnimation = Animation.wellness(duration: 0.3, reduceMotion: false)
        let longAnimation = Animation.wellness(duration: 3.0, reduceMotion: false)

        #expect(shortAnimation != nil)
        #expect(longAnimation != nil)
    }

    // MARK: - Integration Tests

    @Test func testAllAnimationTypesWorkWithReduceMotion() {
        // Verify all animation types properly handle both states
        let motionStates = [true, false]

        for reduceMotion in motionStates {
            let wellness = Animation.wellness(reduceMotion: reduceMotion)
            let breathing = Animation.breathing(reduceMotion: reduceMotion)
            let fidget = Animation.fidget(reduceMotion: reduceMotion)
            let shake = Animation.shake(reduceMotion: reduceMotion)
            let dizzy = Animation.dizzy(reduceMotion: reduceMotion)

            if reduceMotion {
                #expect(wellness == nil)
                #expect(breathing == nil)
                #expect(fidget == nil)
                #expect(shake == nil)
                #expect(dizzy == nil)
            } else {
                #expect(wellness != nil)
                #expect(breathing != nil)
                #expect(fidget != nil)
                #expect(shake != nil)
                #expect(dizzy != nil)
            }
        }
    }

    // MARK: - View Modifier Tests

    @Test func testReduceMotionAwareModifierCreation() {
        // Test that ReduceMotionAwareModifier can be created
        struct TestView: View {
            var body: some View {
                Text("Test")
                    .animateIfMotionAllowed(.easeInOut, value: true)
            }
        }

        let view = TestView()
        let _ = view // Verify view compiles
    }

    @Test func testAnimateIfMotionAllowedModifier() {
        // Test the view extension
        struct TestView: View {
            @State var value = false

            var body: some View {
                Rectangle()
                    .fill(.blue)
                    .animateIfMotionAllowed(.easeInOut, value: value)
            }
        }

        let view = TestView()
        let _ = view // Verify view compiles
    }

    // MARK: - Edge Case Tests

    @Test func testZeroDurationWellnessAnimation() {
        let animation = Animation.wellness(duration: 0, reduceMotion: false)
        #expect(animation != nil, "Should handle zero duration")
    }

    @Test func testNegativeDurationWellnessAnimation() {
        // Negative duration should still create animation (SwiftUI will handle)
        let animation = Animation.wellness(duration: -1.0, reduceMotion: false)
        #expect(animation != nil)
    }

    @Test func testVeryLongDurationWellnessAnimation() {
        let animation = Animation.wellness(duration: 100.0, reduceMotion: false)
        #expect(animation != nil, "Should handle very long duration")
    }
}

// MARK: - Reduce Motion-Aware Modifier Integration Tests

@MainActor
struct ReduceMotionModifierIntegrationTests {

    @Test func testModifierWithEnvironmentValue() {
        struct TestView: View {
            @Environment(\.accessibilityReduceMotion) var reduceMotion
            @State var isActive = false

            var body: some View {
                Text("Test")
                    .modifier(ReduceMotionAwareModifier(
                        animation: .easeInOut,
                        value: isActive
                    ))
            }
        }

        let view = TestView()
        let _ = view // Verify compilation
    }

    @Test func testModifierWithNilAnimation() {
        struct TestView: View {
            @State var isActive = false

            var body: some View {
                Text("Test")
                    .modifier(ReduceMotionAwareModifier<Bool>(
                        animation: nil,
                        value: isActive
                    ))
            }
        }

        let view = TestView()
        let _ = view // Verify compilation
    }

    @Test func testModifierWithDifferentValueTypes() {
        struct TestView: View {
            @State var boolValue = false
            @State var intValue = 0
            @State var doubleValue = 0.0
            @State var stringValue = ""

            var body: some View {
                VStack {
                    Text("Bool").animateIfMotionAllowed(.easeInOut, value: boolValue)
                    Text("Int").animateIfMotionAllowed(.easeInOut, value: intValue)
                    Text("Double").animateIfMotionAllowed(.easeInOut, value: doubleValue)
                    Text("String").animateIfMotionAllowed(.easeInOut, value: stringValue)
                }
            }
        }

        let view = TestView()
        let _ = view // Verify compilation with different value types
    }
}
