import SwiftUI

// MARK: - Motion Decision (D-12/D-13)

/// The single owner of the app's Reduce Motion decision. Every motion-gated
/// effect asks this type; no other file reads the reduce-motion environment
/// value.
enum WellnessMotion {
    /// Pure decision: the SwiftUI reduce-motion environment value OR'd with
    /// the DEBUG verification seam. Non-view callers pass the value captured
    /// through `onMotionDecision(_:)`.
    static func isMotionReduced(reduceMotionEnvironment: Bool) -> Bool {
        #if DEBUG
        if A11yReduceMotionMode.isEnabled() { return true }
        #endif
        return reduceMotionEnvironment
    }

    static func isMotionAllowed(reduceMotionEnvironment: Bool) -> Bool {
        !isMotionReduced(reduceMotionEnvironment: reduceMotionEnvironment)
    }
}

#if DEBUG
/// DEBUG-only scripted verification for Reduce Motion behavior. The
/// environment value is read-only and `simctl` has no toggle for it, so
/// launch with `-a11y-reduce-motion` (Edit Scheme → Run → Arguments) to
/// force the reduced-motion path. Compiled out of Release builds entirely
/// (`MockIAPMode` precedent).
enum A11yReduceMotionMode {
    static let launchArgument = "-a11y-reduce-motion"

    /// Injectable so tests can drive both outcomes without changing the
    /// test process's own launch arguments.
    static func isEnabled(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains(launchArgument)
    }
}
#endif

// MARK: - Motion-Aware Modifiers

/// Applies animation only when the motion decision allows it.
struct ReduceMotionAwareModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion) {
            content
        } else {
            content
                .animation(animation, value: value)
        }
    }
}

/// Hands the helper's motion decision to a view at appear time — the
/// sanctioned way for non-helper code to learn the Reduce Motion state
/// without reading the environment itself.
struct MotionDecisionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let handler: (_ motionReduced: Bool) -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            handler(WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion))
        }
    }
}

/// Runs decorative-animation starters only when the motion decision allows it.
struct MotionAllowedStartModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let start: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            if WellnessMotion.isMotionAllowed(reduceMotionEnvironment: reduceMotion) {
                start()
            }
        }
    }
}

/// Applies the given transition normally and cross-fades when motion is
/// reduced — D-12: fades are allowed, hard cuts are not.
struct MotionAwareTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content.transition(
            WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion)
                ? .opacity
                : transition
        )
    }
}

/// Animation gated on the motion decision and driven by a caller-supplied
/// Equatable value — never a fresh token per body evaluation.
struct AccessibleAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion) {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

/// Press effect whose scale is removed under Reduce Motion.
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let motionAllowed = WellnessMotion.isMotionAllowed(reduceMotionEnvironment: reduceMotion)
        content
            .scaleEffect(isPressed && motionAllowed ? 0.96 : 1.0)
            .animation(motionAllowed ? .easeOut(duration: 0.1) : .none, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

/// Button style whose press-scale is removed under Reduce Motion.
struct MotionAwareScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let motionAllowed = WellnessMotion.isMotionAllowed(reduceMotionEnvironment: reduceMotion)
        return configuration.label
            .scaleEffect(configuration.isPressed && motionAllowed ? 0.95 : 1.0)
            .animation(motionAllowed ? .easeInOut(duration: 0.1) : .none, value: configuration.isPressed)
    }
}

// MARK: - Staggered Appear

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let totalItems: Int
    let baseDelay: Double

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var delay: Double {
        baseDelay * Double(index)
    }

    func body(content: Content) -> some View {
        if WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion) {
            content
        } else {
            content
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                        appeared = true
                    }
                }
        }
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerLoadingModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if WellnessMotion.isMotionReduced(reduceMotionEnvironment: reduceMotion) {
            content.redacted(reason: .placeholder)
        } else {
            content
                .overlay(
                    ShimmerEffectView(phase: $phase)
                )
                .redacted(reason: .placeholder)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

struct ShimmerEffectView: View {
    @Binding var phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
        }
        .mask(Rectangle())
    }
}

// MARK: - Accessible Transitions

extension AnyTransition {
    /// Opacity cross-fade either way — fades are allowed under Reduce Motion (D-12).
    static func accessibleOpacity(motionReduced: Bool) -> AnyTransition {
        .opacity
    }

    /// Scale normally; cross-fade under Reduce Motion.
    static func accessibleScale(motionReduced: Bool) -> AnyTransition {
        motionReduced ? .opacity : .scale
    }

    /// Slide normally; cross-fade under Reduce Motion.
    static func accessibleSlide(motionReduced: Bool, edge: Edge = .bottom) -> AnyTransition {
        motionReduced ? .opacity : .move(edge: edge)
    }
}

// MARK: - View API

extension View {
    /// Apply animation only when the motion decision allows it.
    func animateIfMotionAllowed<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        modifier(ReduceMotionAwareModifier(animation: animation, value: value))
    }

    /// Receive the helper's motion decision (`true` = motion reduced) at appear time.
    func onMotionDecision(_ handler: @escaping (_ motionReduced: Bool) -> Void) -> some View {
        modifier(MotionDecisionModifier(handler: handler))
    }

    /// Start a decorative animation only when the motion decision allows it.
    func startMotionIfAllowed(_ start: @escaping () -> Void) -> some View {
        modifier(MotionAllowedStartModifier(start: start))
    }

    /// Apply `transition` normally and cross-fade under Reduce Motion.
    func motionAwareTransition(_ transition: AnyTransition) -> some View {
        modifier(MotionAwareTransitionModifier(transition: transition))
    }

    /// Animation that respects the motion decision, driven by a real Equatable value.
    func accessibleAnimation<V: Equatable>(
        _ animation: Animation = .easeOut(duration: 0.2),
        value: V
    ) -> some View {
        modifier(AccessibleAnimationModifier(animation: animation, value: value))
    }

    /// Press effect that stops scaling under Reduce Motion.
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }

    /// Applies staggered appear animation for list items; static under Reduce Motion.
    func staggeredAppear(index: Int, total: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearModifier(index: index, totalItems: total, baseDelay: delay))
    }

    /// Applies shimmer loading effect; static redacted placeholder under Reduce Motion.
    func shimmerLoading() -> some View {
        modifier(ShimmerLoadingModifier())
    }
}

// MARK: - Legacy Explicit-Bool Factories (pending deletion — callers migrate in the consolidation sweep)

extension Animation {
    static func wellness(
        duration: Double = 1.0,
        reduceMotion: Bool = false
    ) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration)
    }

    static func breathing(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    }

    static func fidget(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.5)
    }

    static func shake(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)
    }

    static func dizzy(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .linear(duration: 1.5).repeatForever(autoreverses: false)
    }
}
