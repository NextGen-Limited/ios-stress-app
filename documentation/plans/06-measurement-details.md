# Measurement Details

> **Created by:** Phuong Doan
> **Feature:** Detailed view of individual stress measurements
> **Designs Referenced:** 3 screens
> - `measurement_details_view_1`, `measurement_details_view_2`
> - `single_measurement_detail`

---

## Overview

The Measurement Details view shows:
- Full stress level with gauge
- HRV analysis with baseline comparison
- Contributing factors breakdown
- Personalized recommendations

---

## 1. Measurement Detail View

**Design:** `measurement_details_view_1`, `single_measurement_detail`

```swift
// StressMonitor/Views/MeasurementDetailView.swift

import SwiftUI

struct MeasurementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let measurement: StressMeasurement
    @State private var showShareSheet = false

    init(measurement: StressMeasurement) {
        self.measurement = measurement
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Stress level card
                    stressLevelCard

                    // HRV analysis card
                    hrvAnalysisCard

                    // Contributing factors
                    contributingFactorsSection

                    // Recommendations
                    recommendationsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [measurement.shareText])
        }
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.textSecondary)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary.opacity(0.6))

                Text(measurement.timestamp, format: .dateTime.month().day().year())
                    .font(.system(size: 17, weight: .bold))
            }

            Spacer()

            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 24)
    }

    private var stressLevelCard: some View {
        VStack(spacing: 16) {
            Text("Stress Level")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Gauge
            stressGauge

            // Status badge
            statusBadge

            Text(measurement.insightText)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .cardPadding(.spacious)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var stressGauge: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 8)

            Circle()
                .trim(from: 0, to: measurement.stressLevel / 100)
                .stroke(
                    Color.stressColor(for: measurement.category),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(measurement.stressLevel))")
                    .font(.system(size: 48, weight: .bold))

                Text("/ 100")
                    .font(.system(size: 11, weight: .bold))
                    .uppercaseSmallCaps()
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(width: 192, height: 192)
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: measurement.category.iconName)
            Text(measurement.category.displayName)
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(Color.stressColor(for: measurement.category))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.stressColor(for: measurement.category).opacity(0.1))
        .clipShape(Capsule())
    }

    private var hrvAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                        Image(systemName: "waveform.path")
                            .foregroundColor(.primary)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("HRV Analysis")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Heart Rate Variability")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if let trend = measurement.hrvTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.iconName)
                        Text(trend.displayValue)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(measurement.hrv)) ms")
                    .font(.system(size: 32, weight: .bold))

                // Range visualizer
                HRVRangeVisualizer(
                    current: measurement.hrv,
                    baseline: measurement.baselineRange
                )
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var contributingFactorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contributing Factors")
                .font(.system(size: 12, weight: .semibold))
                .uppercaseSmallCaps()
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)

            VStack(spacing: 12) {
                FactorRow(
                    name: "HRV Deviation",
                    value: "High",
                    percentage: 0.75,
                    color: .textMain
                )

                FactorRow(
                    name: "Resting HR",
                    value: "\(Int(measurement.heartRate)) bpm",
                    percentage: 0.45,
                    color: .primary
                )

                FactorRow(
                    name: "Sleep Quality",
                    value: "Fair",
                    percentage: 0.60,
                    color: .warningYellow
                )

                FactorRow(
                    name: "Activity",
                    value: "Low",
                    percentage: 0.30,
                    color: .textSecondary
                )
            }
        }
        .padding(20)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.system(size: 12, weight: .semibold))
                .uppercaseSmallCaps()
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 8)

            ForEach(measurement.recommendations, id: \.self) { recommendation in
                RecommendationRow(recommendation: recommendation)
            }
        }
        .padding(20)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - HRV Range Visualizer
struct HRVRangeVisualizer: View {
    let current: Double
    let baseline: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                // Baseline range indicator
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(
                        width: (baseline.upperBound - baseline.lowerBound) / 100 * (UIScreen.main.bounds.width - 64),
                        height: 8
                    )
                    .cornerRadius(4)
                    .offset(x: (baseline.lowerBound / 100) * (UIScreen.main.bounds.width - 64))

                // Current value marker
                Circle()
                    .fill(Color.primary)
                    .frame(width: 16, height: 16)
                    .offset(x: (current / 100) * (UIScreen.main.bounds.width - 64) - 8)
                    .shadow(radius: 4)
            }

            HStack {
                Text("0ms")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("Baseline: \(Int(baseline.lowerBound))-\(Int(baseline.upperBound))ms")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .bold()

                Spacer()

                Text("100ms")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Factor Row
struct FactorRow: View {
    let name: String
    let value: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .medium))

                Spacer()

                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1))
                    .foregroundColor(color)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 8)
                    .cornerRadius(4)

                Rectangle()
                    .fill(color)
                    .frame(width: max(0, percentage * (UIScreen.main.bounds.width - 64)), height: 8)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let recommendation: String

    var body: some View {
        Button(action: { /* Handle recommendation */ }) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Breathing Exercise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Take a 5-minute resonance breathing break.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Extensions
extension StressMeasurement {
    var insightText: String {
        switch category {
        case .relaxed:
            return "Your stress levels are lower than usual for this time of day."
        case .mild:
            return "Your stress is within a healthy range."
        case .moderate:
            return "Your stress levels are higher than usual for this time of day."
        case .high:
            return "Consider taking a break to reduce your stress levels."
        case .severe:
            return "Your stress levels are elevated. Consider a breathing exercise."
        }
    }

    var recommendations: [String] {
        switch category {
        case .relaxed, .mild:
            return ["Keep up the good work!"]
        case .moderate:
            return ["Breathing Exercise", "Take a short walk"]
        case .high, .severe:
            return ["Breathing Exercise", "Hydration", "Rest"]
        }
    }

    var hrvTrend: MetricTrend? {
        // Would compare with previous measurements
        return nil
    }

    var baselineRange: ClosedRange<Double> {
        50...75
    }

    var shareText: String {
        """
        My Stress Measurement - StressMonitor

        Date: \(timestamp.formatted())
        Stress Level: \(Int(stressLevel))/100
        HRV: \(Int(hrv))ms
        Category: \(category.displayName)

        Track your stress with HRV analysis.
        """
    }
}

// MARK: - Preview
#Preview {
    MeasurementDetailView(
        measurement: StressMeasurement(
            timestamp: Date(),
            stressLevel: 65,
            hrv: 45,
            heartRate: 72,
            confidence: 85,
            category: .moderate
        )
    )
    .preferredColorScheme(.dark)
}
```

---

## 2. Measurement Comparison View

**Design:** `measurement_details_view_2`

Shows side-by-side comparison of two measurements.

```swift
// StressMonitor/Views/MeasurementComparisonView.swift

import SwiftUI

struct MeasurementComparisonView: View {
    let beforeMeasurement: StressMeasurement
    let afterMeasurement: StressMeasurement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.textSecondary)
                                .frame(width: 40, height: 40)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Title
                    Text("Compare Measurements")
                        .font(.title2)
                        .padding(.horizontal, 24)

                    // Date comparison
                    HStack(spacing: 12) {
                        Text(beforeMeasurement.timestamp, format: .dateTime.month().day().year())
                            .font(.body)
                            .foregroundColor(.textSecondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)

                        Text(afterMeasurement.timestamp, format: .dateTime.month().day().year())
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }

                    // Comparison cards
                    VStack(spacing: 16) {
                        ComparisonMetric(
                            title: "Stress Level",
                            beforeValue: beforeMeasurement.stressLevel,
                            afterValue: afterMeasurement.stressLevel,
                            beforeCategory: beforeMeasurement.category,
                            afterCategory: afterMeasurement.category,
                            format: { "\($0)" }
                        )

                        ComparisonMetric(
                            title: "HRV",
                            beforeValue: beforeMeasurement.hrv,
                            afterValue: afterMeasurement.hrv,
                            format: { "\($0) ms" }
                        )

                        ComparisonMetric(
                            title: "Heart Rate",
                            beforeValue: beforeMeasurement.heartRate,
                            afterValue: afterMeasurement.heartRate,
                            format: { "\($0) bpm" }
                        )
                    }
                    .padding(.horizontal, 16)

                    // Change summary
                    changeSummaryCard
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var changeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.flattrend.xyaxis")
                    .foregroundColor(.primary)
                Text("Summary")
                    .font(.system(size: 15, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 8) {
                SummaryRow(
                    icon: "arrow.down",
                    color: afterMeasurement.stressLevel < beforeMeasurement.stressLevel ? .successGreen : .stressHigh,
                    text: "Stress level \(changeDirection(beforeMeasurement.stressLevel, afterMeasurement.stressLevel)) by \(Int(abs(afterMeasurement.stressLevel - beforeMeasurement.stressLevel))) points"
                )

                SummaryRow(
                    icon: "arrow.up",
                    color: afterMeasurement.hrv > beforeMeasurement.hrv ? .successGreen : .stressHigh,
                    text: "HRV \(changeDirection(beforeMeasurement.hrv, afterMeasurement.hrv)) by \(Int(abs(afterMeasurement.hrv - beforeMeasurement.hrv)))ms"
                )
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }

    private func changeDirection(_ before: Double, _ after: Double) -> String {
        after > before ? "increased" : "decreased"
    }
}

struct ComparisonMetric: View {
    let title: String
    let beforeValue: Double
    let afterValue: Double
    let beforeCategory: StressCategory?
    let afterCategory: StressCategory?
    let format: (Double) -> String

    var improvement: Double {
        afterValue - beforeValue
    }

    var isImprovement: Bool {
        if let beforeCategory = beforeCategory, let afterCategory = afterCategory {
            return afterCategory.rawValue < beforeCategory.rawValue
        }
        return improvement < 0 // Lower stress is better
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .uppercaseSmallCaps()
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                // Before
                VStack(alignment: .leading, spacing: 4) {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    if let beforeCategory = beforeCategory {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.stressColor(for: beforeCategory))
                                .frame(width: 8, height: 8)
                            Text(beforeCategory.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                    } else {
                        Text(format(beforeValue))
                            .font(.system(size: 20, weight: .bold))
                    }
                }

                Spacer()

                // Arrow
                Image(systemName: isImprovement ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                    .foregroundColor(isImprovement ? .successGreen : .stressHigh)

                Spacer()

                // After
                VStack(alignment: .trailing, spacing: 4) {
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    if let afterCategory = afterCategory {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.stressColor(for: afterCategory))
                                .frame(width: 8, height: 8)
                            Text(afterCategory.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                    } else {
                        Text(format(afterValue))
                            .font(.system(size: 20, weight: .bold))
                    }
                }
            }

            // Change indicator
            HStack(spacing: 6) {
                Image(systemName: isImprovement ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(isImprovement ? .successGreen : .warningYellow)

                Text("\(Int(abs(improvement)))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isImprovement ? .successGreen : .warningYellow)

                Text(isImprovement ? "better" : "worse")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .cardPadding(.regular)
        .background(Color.cardDark)
        .cornerRadius(16)
    }
}

struct SummaryRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.textMain)
        }
    }
}

// MARK: - Preview
#Preview {
    MeasurementComparisonView(
        beforeMeasurement: StressMeasurement(
            timestamp: Date().addingTimeInterval(-86400),
            stressLevel: 78,
            hrv: 42,
            heartRate: 75,
            confidence: 80,
            category: .high
        ),
        afterMeasurement: StressMeasurement(
            timestamp: Date(),
            stressLevel: 52,
            hrv: 58,
            heartRate: 68,
            confidence: 85,
            category: .mild
        )
    )
    .preferredColorScheme(.dark)
}
```

---

## File Structure

```
StressMonitor/Views/MeasurementDetails/
├── MeasurementDetailView.swift
├── MeasurementComparisonView.swift
└── Components/
    ├── HRVRangeVisualizer.swift
    ├── FactorRow.swift
    ├── RecommendationRow.swift
    └── ComparisonMetric.swift
```

---

## Dependencies

- **Design System:** Colors, components from `00-design-system-components.md`
- **Data Models:** `StressMeasurement`, `StressCategory`
- **ShareSheet:** For sharing measurement data
