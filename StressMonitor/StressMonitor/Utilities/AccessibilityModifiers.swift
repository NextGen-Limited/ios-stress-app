import SwiftUI

/// Accessibility modifiers and helpers for WCAG compliance
extension View {
    /// Applies dual coding for stress levels (color + icon + text)
    /// Required for WCAG AA compliance
    func stressDualCoding(_ category: StressCategory) -> some View {
        modifier(StressDualCodingModifier(category: category))
    }

    /// Ensures minimum touch target size (44x44pt)
    func minimumTouchTarget(_ size: CGFloat = 44) -> some View {
        modifier(MinimumTouchTargetModifier(minSize: size))
    }

    /// Animation that respects accessibility reduce motion preference
    func accessibleAnimation(_ animation: Animation = .easeOut(duration: 0.2)) -> some View {
        modifier(AccessibleAnimationModifier(animation: animation))
    }

    /// Press effect that respects reduce motion
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Dual Coding Modifier

struct StressDualCodingModifier: ViewModifier {
    let category: StressCategory

    func body(content: Content) -> some View {
        HStack(spacing: 6) {
            content

            Image(systemName: category.icon)
                .accessibilityHidden(true)

            Text(category.displayName)
                .font(.caption)
                .foregroundColor(category.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.displayName) stress level")
    }
}

// MARK: - Minimum Touch Target Modifier

struct MinimumTouchTargetModifier: ViewModifier {
    let minSize: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

// MARK: - Accessible Animation Modifier

struct AccessibleAnimationModifier: ViewModifier {
    let animation: Animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

// MARK: - Press Effect Modifier

struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.1), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - VoiceOver Labels

enum VoiceOverLabels {
    // Dashboard
    static let stressRing = "Stress level ring showing current stress as percentage"
    static let measureButton = "Measure current stress level"
    static let hrvCard = "Heart rate variability metric card"
    static let heartRateCard = "Heart rate metric card"

    // Stress Levels
    static func stressLevel(_ level: Double, category: StressCategory) -> String {
        "Stress level \(Int(level)) percent, \(category.displayName)"
    }

    static func stressTrend(_ trend: String) -> String {
        "Stress trend: \(trend)"
    }

    // Timeline
    static func timelinePoint(hour: Int, stress: Double) -> String {
        "At \(hour) hours, stress level was \(Int(stress)) percent"
    }

    // Learning Phase
    static func learningProgress(samples: Int, total: Int, days: Int) -> String {
        "Learning phase: \(samples) of \(total) samples collected, \(days) days remaining"
    }

    // Permissions
    static let permissionCard = "Health access required. Double tap to grant permission."
    static let settingsButton = "Open device settings"
}

// MARK: - Accessibility View Extensions

extension View {
    /// Sets accessibility value and hint for stress level displays
    func accessibilityStressLevel(_ level: Double, category: StressCategory) -> some View {
        self
            .accessibilityValue("\(Int(level)) percent")
            .accessibilityHint(category.accessibilityDescription)
    }

    /// Sets accessibility for chart elements
    func accessibilityChart(description: String, value: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(description)
            .accessibilityValue(value)
            .accessibilityAddTraits(.updatesFrequently)
    }
}
