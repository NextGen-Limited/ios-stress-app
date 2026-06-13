import SwiftUI
import WidgetKit

/// Small widget view — **character-reactive face only, no numeric score**.
///
/// The Ripple 💧 character's expression and accent ring *are* the stress indicator.
@available(iOS 17.0, *)
public struct SmallWidgetView: View {

    let entry: StressEntry

    public init(entry: StressEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(spacing: 0) {
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

        VStack(spacing: 6) {
            WidgetCharacterFace(tier: tier, size: 68, showsRing: true, glow: true)

            Text(tier.label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(tier.accent)
                .contentTransition(.opacity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 6) {
            WidgetCharacterFace(tier: .balanced, size: 60, showsRing: true)
                .opacity(0.5)
            Text("StressMonitor")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("💧")
                .font(.system(size: 32))
            Text("No Data")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            Text("Open app to measure")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    SmallWidgetView(entry: StressEntry(
        date: Date(),
        latestStress: StressData(
            level: 35,
            category: "mild",
            hrv: 55,
            heartRate: 68,
            confidence: 0.85,
            timestamp: Date()
        ),
        history: [],
        baseline: (50.0, 60.0),
        isPlaceholder: false
    ))
    .previewContext(WidgetPreviewContext(family: .systemSmall))
}
