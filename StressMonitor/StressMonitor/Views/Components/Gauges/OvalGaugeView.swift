import SwiftUI

// MARK: - OvalGaugeView

/// Horizontal pill gauge representing a stress score (0–100).
///
/// Same stress-tier vocabulary as ``TideGaugeView`` laid out along the
/// horizontal axis. A white marker circle anchors the current position.
/// Used where a compact horizontal indicator is preferred over the vertical
/// tide gauge.
struct OvalGaugeView: View {
    /// Stress score in the range 0 ... 100.
    let score: Double
    /// Width of the gauge track in points.
    var width: CGFloat = 200
    /// Height of the gauge track in points.
    var height: CGFloat = 24

    private var clampedScore: CGFloat {
        CGFloat(min(max(score, 0), 100))
    }

    private var clampedPosition: CGFloat {
        clampedScore / 100
    }

    var body: some View {
        ZStack(alignment: .leading) {
            track
            fill
            marker
        }
        .frame(width: width, height: height)
        .accessibilityElement()
        .accessibilityLabel("Stress level gauge")
        .accessibilityValue("\(Int(clampedScore)) percent")
    }

    private var track: some View {
        Capsule()
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.15))
    }

    private var fill: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: StressTierPalette.verticalGradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(height, width * clampedPosition))
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: score)
    }

    private var marker: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .frame(width: height + 6, height: height + 6)
            .offset(x: (width * clampedPosition) - (height + 6) / 2)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: score)
    }
}

// MARK: - Previews

#Preview("Oval Gauge") {
    VStack(spacing: 24) {
        OvalGaugeView(score: 18)
        OvalGaugeView(score: 42)
        OvalGaugeView(score: 66)
        OvalGaugeView(score: 91)
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
