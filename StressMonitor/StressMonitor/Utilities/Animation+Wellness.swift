import SwiftUI

// MARK: - Reduce Motion Support

extension Animation {
    /// Wellness animation with Reduce Motion support
    /// Returns nil if Reduce Motion is enabled, allowing static fallback
    /// - Parameters:
    ///   - duration: Animation duration in seconds
    ///   - reduceMotion: Whether Reduce Motion is enabled
    /// - Returns: Animation or nil if motion should be reduced
    static func wellness(
        duration: Double = 1.0,
        reduceMotion: Bool = false
    ) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration)
    }

    /// Breathing animation (slow, gentle)
    static func breathing(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    }

    /// Fidget animation (quick, subtle)
    static func fidget(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.5)
    }

    /// Shake animation (fast, alert)
    static func shake(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)
    }

    /// Dizzy animation (continuous rotation)
    static func dizzy(reduceMotion: Bool = false) -> Animation? {
        reduceMotion ? nil : .linear(duration: 1.5).repeatForever(autoreverses: false)
    }
}

// MARK: - Reduce Motion-Aware Modifier

/// View modifier that applies animation only when Reduce Motion is disabled
struct ReduceMotionAwareModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            // Static - no animation
            content
        } else {
            // Animated
            content
                .animation(animation, value: value)
        }
    }
}

extension View {
    /// Apply animation only when Reduce Motion is disabled
    /// - Parameters:
    ///   - animation: Animation to apply
    ///   - value: Value to trigger animation
    /// - Returns: View with conditional animation
    func animateIfMotionAllowed<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        modifier(ReduceMotionAwareModifier(animation: animation, value: value))
    }
}

// MARK: - Accessibility-Safe Transition

extension AnyTransition {
    /// Safe opacity transition that respects Reduce Motion
    static func accessibleOpacity(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .identity // No transition
        } else {
            return .opacity
        }
    }

    /// Safe scale transition that respects Reduce Motion
    static func accessibleScale(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .identity
        } else {
            return .scale
        }
    }

    /// Safe slide transition that respects Reduce Motion
    static func accessibleSlide(reduceMotion: Bool, edge: Edge = .bottom) -> AnyTransition {
        if reduceMotion {
            return .identity
        } else {
            return .move(edge: edge)
        }
    }
}
