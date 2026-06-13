import SwiftUI
import Charts
import WidgetKit

/// Medium widget — **character face + mini trend sparkline, no numeric score**.
@available(iOS 17.0, *)
public struct MediumWidgetView: View {

    let entry: StressEntry

    public init(entry: StressEntry) {
        self.entry = entry
    }

    public var body: some View {
        HStack(spacing: 0) {
            if entry.isPlaceholder {
                placeholderView
            } else if let stress = entry.latestStress {
                stressContent(stress: stress)
            } else {
                emptyStateView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Character-Reactive Content

    @ViewBuilder
    private func stressContent(stress: StressData) -> some View {
        let tier = WidgetStressTier.from(level: stress.level)

        HStack(spacing: 12) {
            // Left: Character face
            VStack(spacing: 4) {
                WidgetCharacterFace(tier: tier, size: 56, showsRing: true, glow: true)

                Text(tier.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(tier.accent)
            }
            .frame(width: 90)
            .padding(.leading, 8)

            // Right: Mini trend sparkline (colour-coded, no axis numbers)
            if entry.history.count >= 2 {
                sparklineSection(tier: tier)
            } else {
                // Not enough data — show character mood descriptor
                VStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20))
                        .foregroundColor(tier.accent.opacity(0.6))
                    Text("Gathering data…")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func sparklineSection(tier: WidgetStressTier) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Trend")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)

            Chart(Array(entry.history.suffix(12)), id: \.timestamp) { item in
                let pTier = WidgetStressTier.from(level: item.level)
                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Stress", item.level)
                )
                .foregroundStyle(pTier.accent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 50)
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing, 12)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        HStack(spacing: 12) {
            WidgetCharacterFace(tier: .balanced, size: 50, showsRing: true)
                .opacity(0.5)
            Text("StressMonitor")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("💧")
                .font(.system(size: 28))
            Text("No Data")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
            Text("Open StressMonitor to measure")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(12)
    }
}

// MARK: - Preview

private extension StressEntry {
    static var previewMedium: StressEntry {
        let now = Date()
        let latest = StressData(
            level: 55, category: "moderate", hrv: 42,
            heartRate: 75, confidence: 0.8, timestamp: now
        )
        let history: [StressData] = (0..<8).map { i in
            StressData(
                level: Double(40 + i * 3),
                category: "mild", hrv: 50, heartRate: 70,
                confidence: 0.85,
                timestamp: now.addingTimeInterval(TimeInterval(-i * 3600))
            )
        }
        return StressEntry(
            date: now,
            latestStress: latest,
            history: history,
            baseline: (50.0, 60.0),
            isPlaceholder: false
        )
    }
}

@available(iOS 17.0, *)
#Preview {
    MediumWidgetView(entry: .previewMedium)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
}
