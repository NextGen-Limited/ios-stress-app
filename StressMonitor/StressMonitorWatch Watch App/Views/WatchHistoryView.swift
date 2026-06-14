import SwiftUI

/// Watch **History** screen.
///
/// A simple list of recent stress readings (last 7 days), colour-coded by the
/// Ripple character's expression. Each row shows the character face, a relative
/// time, and an accent dot — **never a numeric score**.
struct WatchHistoryView: View {
    @Bindable var viewModel: WatchStressViewModel

    private let readings: [SharedReading]

    init(viewModel: WatchStressViewModel) {
        self.viewModel = viewModel
        self.readings = WatchSharedDataStore.shared.history7Days
    }

    var body: some View {
        Group {
            if readings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(readings) { reading in
                            HistoryRow(reading: reading)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StressCharacterPalette.darkCanvas.ignoresSafeArea())
        .navigationTitle("History")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            CharacterFaceView(tier: .veryCalm, size: 70, glow: true)
            Text("No readings yet")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text("Take a measurement to see your history here.")
                .font(.system(size: 10))
                .foregroundStyle(StressCharacterPalette.mutedInk)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private struct HistoryRow: View {
    let reading: SharedReading

    var body: some View {
        HStack(spacing: 10) {
            CharacterFaceView(tier: reading.tier, size: 36, showsRing: true)

            VStack(alignment: .leading, spacing: 1) {
                Text(reading.tier.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(reading.tier.accent)
                Text(reading.timestamp.formatted(.relative(presentation: .named)))
                    .font(.system(size: 9))
                    .foregroundStyle(StressCharacterPalette.mutedInk)
            }

            Spacer(minLength: 0)

            // Accent dot reinforces the colour-coded tier.
            Circle()
                .fill(reading.tier.accent)
                .frame(width: 9, height: 9)
        }
        .padding(8)
        .background(StressCharacterPalette.darkCard.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("\(reading.tier.label), \(reading.timestamp.formatted(.relative(presentation: .named)))")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchHistoryView(viewModel: WatchStressViewModel())
    }
}
#endif
