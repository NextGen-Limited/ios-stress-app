import SwiftUI

/// Distribution stacked bar matching `06-trends.html` section 3.
///
/// Four segments (Relaxed / Mild / Moderate / High) rendered as a single
/// horizontal bar whose widths always sum to 100%. Below the bar sits a
/// 2×2 legend grid showing day-counts per tier, plus an editorial comment.
struct DistributionBar: View {
    let relaxedDays: Int
    let mildDays: Int
    let moderateDays: Int
    let highDays: Int
    var comment: String? = nil

    // MARK: - Derived

    private var totalDays: Int {
        relaxedDays + mildDays + moderateDays + highDays
    }

    /// Exact percentages that always sum to 100. Last non-zero segment
    /// absorbs the rounding residual.
    private var segments: (relaxed: Int, mild: Int, moderate: Int, high: Int) {
        guard totalDays > 0 else { return (0, 0, 0, 0) }
        let t = Double(totalDays)
        let rPct = (Double(relaxedDays) / t * 100).rounded()
        let mPct = (Double(mildDays) / t * 100).rounded()
        let moPct = (Double(moderateDays) / t * 100).rounded()
        let hPct = max(0, 100 - rPct - mPct - moPct)
        return (Int(rPct), Int(mPct), Int(moPct), Int(hPct))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            bar
            legend
            if let comment {
                Text(comment)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Time spent by tier. Relaxed \(segments.relaxed) percent. " +
            "Mild \(segments.mild) percent. Moderate \(segments.moderate) percent. " +
            "High \(segments.high) percent."
        )
    }

    // MARK: - Bar

    private var bar: some View {
        GeometryReader { proxy in
            let total = max(proxy.size.width, 1)
            let s = segments
            HStack(spacing: 0) {
                if s.relaxed > 0 {
                    barSegment(
                        color: StressCategory.relaxed.color,
                        width: total * CGFloat(s.relaxed) / 100,
                        label: "\(s.relaxed)%"
                    )
                }
                if s.mild > 0 {
                    barSegment(
                        color: StressCategory.mild.color,
                        width: total * CGFloat(s.mild) / 100,
                        label: "\(s.mild)%"
                    )
                }
                if s.moderate > 0 {
                    barSegment(
                        color: StressCategory.moderate.color,
                        width: total * CGFloat(s.moderate) / 100,
                        label: "\(s.moderate)%",
                        darkText: true
                    )
                }
                if s.high > 0 {
                    barSegment(
                        color: StressCategory.high.color,
                        width: total * CGFloat(s.high) / 100,
                        label: "\(s.high)%"
                    )
                }
            }
        }
        .frame(height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func barSegment(color: Color, width: CGFloat, label: String, darkText: Bool = false) -> some View {
        ZStack {
            Rectangle().fill(color)
            if width > 32 {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(darkText ? Color.black.opacity(0.65) : Color.white)
            }
        }
        .frame(width: max(0, width))
    }

    // MARK: - Legend

    private var legend: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 8
        ) {
            legendItem(tier: .relaxed, label: "Relaxed", days: relaxedDays)
            legendItem(tier: .mild, label: "Mild", days: mildDays)
            legendItem(tier: .moderate, label: "Moderate", days: moderateDays)
            legendItem(
                tier: .high,
                label: "High",
                days: highDays,
                dimmed: highDays == 0
            )
        }
    }

    private func legendItem(tier: StressCategory, label: String, days: Int, dimmed: Bool = false) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(tier.color)
                .frame(width: 10, height: 10)
                .stressDualCoding(tier, showsCaption: false)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            Spacer(minLength: 0)
            Text("\(days) day\(days == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(dimmed ? 0.45 : 1))
        }
        .opacity(dimmed ? 0.45 : 1)
    }
}

#Preview("DistributionBar") {
    VStack(spacing: 20) {
        DistributionBar(
            relaxedDays: 2,
            mildDays: 3,
            moderateDays: 2,
            highDays: 0,
            comment: "Most days landed in Mild — your baseline is shifting in the right direction."
        )
        Spacer()
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}
