import SwiftUI

/// Animation presets for consistent timing across the app.
/// All durations follow 150-300ms guidelines for micro-interactions.
/// The values are inert on their own — apply them through
/// `animateIfMotionAllowed(_:value:)` (Animation+Wellness.swift) so preset
/// users inherit the app-wide Reduce Motion decision without reading
/// anything themselves.
extension Animation {
    /// Quick micro-interaction (100ms)
    static let micro = Animation.easeOut(duration: 0.1)

    /// Standard micro-interaction (150ms)
    static let quick = Animation.easeOut(duration: 0.15)

    /// Standard interaction (250ms)
    static let standard = Animation.easeOut(duration: 0.25)

    /// Emphasis animation (350ms)
    static let emphasis = Animation.easeOut(duration: 0.35)

    /// Spring animation for bouncy feel
    static let springy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Stiff spring for quick feedback
    static let stiffSpring = Animation.spring(response: 0.2, dampingFraction: 0.8)

    /// Slow spring for dramatic effect
    static let slowSpring = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Smooth ease for state transitions
    static let smooth = Animation.easeInOut(duration: 0.3)
}

// MARK: - Preview

#Preview("Animation Presets Demo") {
    VStack(spacing: 20) {
        Text("Animation Presets")
            .font(.headline)

        Text("Micro, Quick, Standard, Emphasis")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.oledBackground)
}
