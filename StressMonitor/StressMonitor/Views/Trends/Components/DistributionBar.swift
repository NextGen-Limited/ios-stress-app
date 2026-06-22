import SwiftUI

/// Stacked horizontal distribution bar with three segments — relaxed / mixed /
/// high — plus a legend row beneath.
///
/// The view takes raw percentages and renders them with a guaranteed-sum of
/// 100%: the last segment absorbs rounding error so the visible widths always
/// fill the bar exactly. This is the math contract from the Trends spec.
struct DistributionBar: View {
    let relaxedPercent: Double
    let mixedPercent: Double
    let highPercent: Double

    /// Adjusted segment widths that always sum to 100.
    /// The high segment absorbs the rounding residual.
    private var segments: (relaxed: Double, mixed: Double, high: Double) {
        let raw = [relaxedPercent, mixedPercent, highPercent]
        let rawSum = raw.reduce(0, +)
        guard rawSum > 0 else { return (0, 0, 0) }
        // Normalize to 100 first so callers can pass counts or unnormalized %.
        let normalized = raw.map { ($0 / rawSum) * 100 }
        let relaxed = (normalized[0]).rounded()
        let mixed = (normalized[1]).rounded()
        // Last segment = 100 - others, so the three always sum to exactly 100.
        let high = 100 - relaxed - mixed
        return (relaxed, mixed, high)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            bar
            legend
        }
        .padding(18)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Stress distribution. Relaxed \(Int(segments.relaxed)) percent. " +
            "Mixed \(Int(segments.mixed)) percent. High \(Int(segments.high)) percent."
        )
    }

    private var bar: some View {
        GeometryReader { proxy in
            let total = max(proxy.size.width, 1)
            let s = segments
            HStack(spacing: 2) {
                segment(fill: TrendsPalette.tierVeryCalm, width: total * (s.relaxed / 100))
                segment(fill: TrendsPalette.tierNeutral, width: total * (s.mixed / 100))
                segment(fill: TrendsPalette.tierCritical, width: total * (s.high / 100))
            }
        }
        .frame(height: 14)
        .clipShape(Capsule())
    }

    private func segment(fill: Color, width: CGFloat) -> some View {
        Rectangle()
            .fill(fill)
            .frame(width: max(0, width))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: TrendsPalette.tierVeryCalm, label: "Relaxed", percent: segments.relaxed)
            legendItem(color: TrendsPalette.tierNeutral, label: "Mixed", percent: segments.mixed)
            legendItem(color: TrendsPalette.tierCritical, label: "High", percent: segments.high)
            Spacer(minLength: 0)
        }
    }

    private func legendItem(color: Color, label: String, percent: Double) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(percent))% \(label)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
    }
}

#Preview("DistributionBar") {
    VStack(spacing: 20) {
        DistributionBar(relaxedPercent: 33.3, mixedPercent: 33.3, highPercent: 33.4)
        DistributionBar(relaxedPercent: 55, mixedPercent: 30, highPercent: 15)
        DistributionBar(relaxedPercent: 0, mixedPercent: 0, highPercent: 0)
        Spacer()
    }
    .padding()
}
