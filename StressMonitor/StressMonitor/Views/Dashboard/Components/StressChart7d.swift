import SwiftUI

// MARK: - StressChart7d

/// 7-day stress bar chart with horizontal gridlines, threshold bands, and a
/// compact legend. Bars are color-coded by stress category. The "today" bar
/// is highlighted with a thicker width and a dot indicator.
///
/// Spec reference: design/screens/04-home.html — `.chart-card` / `.bars`.
struct StressChart7d: View {
    struct DayBar: Identifiable {
        let id = UUID()
        let dayLabel: String        // "M", "T", "W"…
        let value: Double           // 0–100
        let isToday: Bool
    }

    let bars: [DayBar]

    init(bars: [DayBar]) {
        self.bars = bars
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stress over time")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text("Last 7 days")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "777986"))
                }
                Spacer()
                legendChip
            }

            chartArea
        }
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("7-day stress chart. Average \(String(format: "%.0f", bars.map(\.value).reduce(0, +) / Double(max(bars.count, 1))))")
    }

    // MARK: - Chart Area

    private var chartArea: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height
            let barAreaWidth = geo.size.width / CGFloat(max(bars.count, 1))
            let barWidth: CGFloat = 14

            ZStack(alignment: .bottomLeading) {
                gridlines(height: chartHeight)

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                        VStack(spacing: 6) {
                            // Bar
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(StressCategory.color(for: bar.value).opacity(bar.isToday ? 1.0 : 0.78))
                                .frame(width: bar.isToday ? barWidth + 4 : barWidth,
                                       height: max(barHeight(for: bar.value, in: chartHeight), 4))

                            // Today indicator dot
                            if bar.isToday {
                                Circle()
                                    .fill(StressCategory.color(for: bar.value))
                                    .frame(width: 5, height: 5)
                            } else {
                                Color.clear.frame(height: 5)
                            }

                            // Day label
                            Text(bar.dayLabel)
                                .font(.system(size: 11, weight: bar.isToday ? .bold : .medium))
                                .foregroundStyle(bar.isToday ? StressCategory.color(for: bar.value) : Color(hex: "777986"))
                        }
                        .frame(width: barAreaWidth, height: chartHeight + 22, alignment: .bottom)
                    }
                }
            }
        }
        .frame(height: 130)
    }

    // MARK: - Gridlines

    private func gridlines(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<5) { i in
                Rectangle()
                    .fill(Color(hex: "3C3C43").opacity(i == 0 ? 0 : 0.07))
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(height: height)
    }

    // MARK: - Legend

    private var legendChip: some View {
        HStack(spacing: 8) {
            legendItem(color: Color.stressRelaxed, label: "Relaxed")
            legendItem(color: Color.stressMild, label: "Mild")
            legendItem(color: Color.stressHigh, label: "High")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.3)
                .foregroundStyle(Color(hex: "777986"))
        }
    }

    // MARK: - Helpers

    private func barHeight(for value: Double, in chartHeight: CGFloat) -> CGFloat {
        let clamped = max(0, min(100, value))
        return chartHeight * CGFloat(clamped / 100) * 0.85
    }
}

// MARK: - StressCategory Color Helper

private extension StressCategory {
    static func color(for level: Double) -> Color {
        StressResult.category(for: level).color
    }
}

// MARK: - Preview

#Preview("StressChart7d") {
    let sample = StressChart7d.DayBar(dayLabel: "W", value: 48, isToday: false)
    let _ = StressChart7d.DayBar(dayLabel: "T", value: 35, isToday: false)
    let _ = StressChart7d.DayBar(dayLabel: "F", value: 62, isToday: false)

    VStack {
        StressChart7d(bars: [
            .init(dayLabel: "M", value: 38, isToday: false),
            .init(dayLabel: "T", value: 52, isToday: false),
            .init(dayLabel: "W", value: 45, isToday: false),
            .init(dayLabel: "T", value: 68, isToday: false),
            .init(dayLabel: "F", value: 30, isToday: false),
            .init(dayLabel: "S", value: 22, isToday: false),
            .init(dayLabel: "S", value: 42, isToday: true),
        ])
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
