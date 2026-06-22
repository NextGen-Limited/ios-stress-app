import SwiftUI

// MARK: - TideGaugeView

/// Vertical "tide" gauge that fills from bottom to top to represent a 0–1 position.
///
/// The fill gradient spans the five stress tiers (relaxed → severe). A floating
/// marker dot anchors the current position. `barHeight` is exposed so callers
/// can fit the gauge into cards of varying height; the default of 140 matches
/// the home card layout.
struct TideGaugeView: View {
    /// Normalized position in the range 0.0 ... 1.0.
    let position: Double
    /// Height of the gauge track in points.
    var barHeight: CGFloat = 140
    /// Width of the gauge track in points.
    var barWidth: CGFloat = 16

    private var clampedPosition: CGFloat {
        CGFloat(min(max(position, 0), 1))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            track
            fill
            marker
        }
        .frame(width: barWidth, height: barHeight)
        .accessibilityElement()
        .accessibilityLabel("Stress tide gauge")
        .accessibilityValue("\(Int(clampedPosition * 100)) percent")
    }

    private var track: some View {
        RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.15))
    }

    private var fill: some View {
        RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: StressTierPalette.verticalGradient,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: max(barWidth, barHeight * clampedPosition))
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: position)
    }

    private var marker: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .frame(width: barWidth + 6, height: barWidth + 6)
            .offset(y: -(barHeight * clampedPosition) + (barWidth + 6) / 2)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: position)
    }
}

// MARK: - Stress Tier Palette

enum StressTierPalette {
    /// Five-stop gradient from relaxed (bottom) to severe (top).
    static let verticalGradient: [Color] = [
        StressCategory.relaxed.color,
        StressCategory.mild.color,
        StressCategory.moderate.color,
        StressCategory.high.color,
        StressCategory.severe.color,
    ]
}

// MARK: - Previews

#Preview("Tide Gauge") {
    HStack(spacing: 32) {
        TideGaugeView(position: 0.18, barHeight: 140)
        TideGaugeView(position: 0.42, barHeight: 140)
        TideGaugeView(position: 0.66, barHeight: 140)
        TideGaugeView(position: 0.91, barHeight: 140)
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
