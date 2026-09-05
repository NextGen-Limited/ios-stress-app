import SwiftUI

/// Accessibility modifiers and helpers for WCAG compliance
extension View {
    /// Applies dual coding for stress levels (color + icon + text)
    /// Required for WCAG AA compliance
    /// - Parameter showsCaption: false when the content already renders the
    ///   category's display name (prevents a duplicated visible name); the
    ///   symbol channel and combined label are still applied.
    func stressDualCoding(_ category: StressCategory, showsCaption: Bool = true) -> some View {
        modifier(StressDualCodingModifier(category: category, showsCaption: showsCaption))
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
    var showsCaption: Bool = true

    func body(content: Content) -> some View {
        HStack(spacing: 6) {
            content

            Image(systemName: category.icon)
                .accessibilityHidden(true)

            if showsCaption {
                Text(category.displayName)
                    .font(.caption)
                    .foregroundColor(Color.Wellness.adaptiveSecondaryText)
            }
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

    /// One-line trend summary for a chart series (D-09 contract):
    /// "{Metric} {up|down|steady} {percent}% in the last {period}" —
    /// steady omits the percent token. A single-point series and an
    /// exactly-zero relative change both classify as steady; the percent is
    /// the relative change between the first and last values, rounded to a
    /// whole number. A zero baseline makes the percent uncomputable, so the
    /// direction word is kept and the percent token omitted.
    static func trendSummary(metric: String, values: [Double], period: String) -> String {
        let steady = "\(metric) steady in the last \(period)"
        guard let first = values.first, let last = values.last, first != last else {
            return steady
        }
        let direction = last > first ? "up" : "down"
        guard first != 0 else {
            return "\(metric) \(direction) in the last \(period)"
        }
        let percent = Int((abs(last - first) / abs(first) * 100).rounded())
        guard percent > 0 else {
            return steady
        }
        return "\(metric) \(direction) \(percent)% in the last \(period)"
    }

    /// Per-point chart series label (D-09 contract): "{date}: {value}{unit}"
    /// — e.g. "Sep 3: 48 ms". Inputs restate exactly what the chart renders.
    static func chartPoint(dateText: String, valueText: String, unit: String = "") -> String {
        unit.isEmpty ? "\(dateText): \(valueText)" : "\(dateText): \(valueText) \(unit)"
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

    /// Chart accessibility series (D-09): the chart keeps fixed-size geometry
    /// while the container carries its descriptive label, the one-line trend
    /// summary as the VoiceOver value (the entry point), and the per-point
    /// series after it. Child containment keeps per-element labels navigable
    /// inside the container.
    func accessibilityChart(description: String, summary: String, points: [String]) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(description)
            .accessibilityValue(([summary] + points).joined(separator: ", "))
            .accessibilityAddTraits(.updatesFrequently)
    }
}
