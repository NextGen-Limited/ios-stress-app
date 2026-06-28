import SwiftUI

/// Watch **Workout** screen — live heart-rate zones during a workout.
///
/// Big BPM number, current-zone badge with zone colour, elapsed time,
/// a compact per-zone distribution mini-chart, and a Stop button.
/// Tracks light surfaces, ink ramp, and radii from `WatchDesignTokens`.
struct WatchWorkoutView: View {
    @State private var viewModel = WatchWorkoutViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                hrHero
                zoneBadge
                elapsedRow
                zoneDistribution
                stopButton
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !viewModel.isRunning {
                viewModel.start(maxHR: 190)
            }
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    // MARK: - HR hero

    private var hrHero: some View {
        VStack(spacing: 2) {
            Text("HEART RATE")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                .tracking(0.05 * 7.5)
                .foregroundStyle(WatchDesignTokens.muted)

            Text("\(Int(viewModel.currentHR))")
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.02 * 48)
                .foregroundStyle(WatchDesignTokens.ink)

            Text("BPM")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.04 * 9)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Zone badge

    private var zoneBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(zoneColor)
                .frame(width: 8, height: 8)
            Text(viewModel.currentZone.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchDesignTokens.ink)
            Text(viewModel.currentZone.description.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(0.04 * 8)
                .foregroundStyle(WatchDesignTokens.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Elapsed time

    private var elapsedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchDesignTokens.muted)
            Text(timeString(viewModel.elapsedSeconds))
                .font(.system(size: 13, weight: .semibold, design: .monospaced).monospacedDigit())
                .tracking(0.02 * 13)
                .foregroundStyle(WatchDesignTokens.ink)
            Spacer(minLength: 0)
            Text("ELAPSED")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                .tracking(0.05 * 7.5)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusControl, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Zone distribution mini-chart

    private var zoneDistribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ZONE TIME")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            HStack(spacing: 3) {
                ForEach(WorkoutZone.allCases, id: \.self) { zone in
                    bar(for: zone)
                }
            }
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    private func bar(for zone: WorkoutZone) -> some View {
        let total = viewModel.zoneTimeSummary.values.reduce(0, +)
        let value = viewModel.zoneTimeSummary[zone] ?? 0
        let ratio = total > 0 ? Double(value) / Double(total) : 0
        let height = max(4, ratio * 36)
        return VStack(spacing: 2) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: zone.colorHex))
                .frame(maxWidth: .infinity)
                .frame(height: height)
            Text("\(zone.rawValue)")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel("\(zone.displayName), \(value) seconds")
    }

    // MARK: - Stop

    private var stopButton: some View {
        Button {
            viewModel.stop()
        } label: {
            Text("Stop")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Capsule(style: .continuous)
                        .fill(WatchDesignTokens.accentStrong)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var zoneColor: Color {
        Color(hex: viewModel.currentZone.colorHex)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchWorkoutView()
    }
}
#endif
