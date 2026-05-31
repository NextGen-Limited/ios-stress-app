import SwiftUI

/// Enhanced metric card with optional mini chart and trend indicator
struct MetricCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let trend: Trend?
    let chartData: [Double]?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Trend Types

    enum Trend {
        case up(String)    // Value to display (e.g., "+5%")
        case down(String)  // Value to display (e.g., "-2 bpm")
        case stable

        var color: Color {
            switch self {
            case .down: return .stressRelaxed
            case .up: return .stressHigh
            case .stable: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var displayValue: String {
            switch self {
            case .up(let v), .down(let v): return v
            case .stable: return "—"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.oledTextSecondary)

                Spacer()
            }

            // Value row with animation
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(
                        reduceMotion ? .identity : .numericText()
                    )
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7),
                        value: value
                    )

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(Color.oledTextSecondary)
                }

                Spacer()
            }

            // Chart or trend indicator - fixed height for equal card heights
            Group {
                if let chartData = chartData, !chartData.isEmpty {
                    MiniLineChartView(dataPoints: chartData, color: iconColor)
                } else if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trend.displayValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend.color)
                    .frame(height: 40, alignment: .leading)
                }
            }
            .frame(height: 40)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.oledCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(value) \(unit)")
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = title
        if let trend = trend {
            label += ", trend: \(trend.displayValue)"
        }
        return label
    }
}

// MARK: - Convenience Initializers

extension MetricCardView {
    /// HRV metric card with chart
    static func hrv(value: String, chartData: [Double]) -> MetricCardView {
        MetricCardView(
            icon: "heart.fill",
            iconColor: .hrvAccent,
            title: "HRV",
            value: value,
            unit: "ms",
            trend: nil,
            chartData: chartData
        )
    }

    /// Heart rate metric card with trend
    static func heartRate(value: String, trendValue: String, isDown: Bool) -> MetricCardView {
        MetricCardView(
            icon: "heart.fill",
            iconColor: .heartRateAccent,
            title: "RESTING HR",
            value: value,
            unit: "bpm",
            trend: isDown ? .down(trendValue) : .up(trendValue),
            chartData: nil
        )
    }
}

#Preview("Metric Cards") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        HStack(spacing: 12) {
            MetricCardView.hrv(
                value: "65",
                chartData: [45, 52, 48, 55, 50, 58, 65]
            )

            MetricCardView.heartRate(
                value: "58",
                trendValue: "-2 bpm",
                isDown: true
            )
        }
        .padding()
    }
}
