import SwiftUI

/// Watch **Workout** screen — live heart-rate zones during a workout.
///
/// Big BPM number, current-zone badge with zone colour, elapsed time,
/// a compact per-zone distribution mini-chart, and a Stop button.
/// Tracks light surfaces, ink ramp, and radii from `WatchDesignTokens`.
struct WatchWorkoutView: View {
    @State private var viewModel = WatchWorkoutViewModel()

    @ScaledMetric(relativeTo: .caption2) private var caption2Scale: CGFloat = 1
    @ScaledMetric(relativeTo: .footnote) private var footnoteScale: CGFloat = 1
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleScale: CGFloat = 1
    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                hrHero
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

    // MARK: - HR hero (with zone badge)

    private var hrHero: some View {
        VStack(spacing: 2) {
            Text("HEART RATE")
                .font(.system(size: 8 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.08 * 8)
                .foregroundStyle(WatchDesignTokens.muted)

            Text("\(Int(viewModel.currentHR))")
                .font(.system(size: 54 * largeTitleScale, weight: .bold, design: .rounded).monospacedDigit())
                .tracking(-0.03 * 54)
                .foregroundStyle(WatchDesignTokens.ink)

            Text("BPM")
                .font(.system(size: 8 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.08 * 8)
                .foregroundStyle(WatchDesignTokens.muted)

            zoneRow
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Zone row (inside HR hero)

    private var zoneRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(zoneColor)
                .frame(width: 7, height: 7)
            Text("\(viewModel.currentZone.displayName) · \(viewModel.currentZone.description)")
                .font(.system(size: 11 * caption2Scale, weight: .semibold, design: .default))
                .foregroundStyle(viewModel.currentZone == .zone3 ? Color(hex: "#B59400") : WatchDesignTokens.ink)
            Spacer(minLength: 0)
            Text(viewModel.currentZone.description.uppercased())
                .font(.system(size: 7 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
    }

    // MARK: - Elapsed time

    private var elapsedRow: some View {
        HStack(spacing: 7) {
            Image(systemName: "timer")
                .font(.system(size: 11 * caption2Scale, weight: .semibold))
                .foregroundStyle(WatchDesignTokens.muted)
            Text(timeString(viewModel.elapsedSeconds))
                .font(.system(size: 13 * footnoteScale, weight: .semibold, design: .monospaced).monospacedDigit())
                .tracking(0.02 * 13)
                .foregroundStyle(WatchDesignTokens.ink)
            Spacer(minLength: 0)
            Text("ELAPSED")
                .font(.system(size: 7 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Zone distribution mini-chart

    private var zoneDistribution: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ZONE TIME")
                .font(.system(size: 8.5 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(WorkoutZone.allCases, id: \.self) { zone in
                    bar(for: zone)
                }
            }
            .frame(height: 54)
        }
        .padding(.horizontal, 6)
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
        let height = max(6, ratio * 46)
        return VStack(spacing: 3) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: zone.colorHex))
                .frame(width: 22, height: height)
            Text("\(zone.rawValue)")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced)) // dated exception 2026-09-05: chart geometry — label sits under fixed-width zone bars (D-09)
                .tracking(0.04 * 7.5)
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
                .font(.system(size: 14 * footnoteScale, weight: .semibold, design: .rounded))
                .tracking(-0.01 * 14)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 36)
                .background(
                    Capsule(style: .continuous)
                        .fill(WatchDesignTokens.accentStrong)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
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
