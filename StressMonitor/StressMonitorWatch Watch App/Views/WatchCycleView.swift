import SwiftUI

/// Watch **Cycle** screen — current menstrual-cycle phase and context.
///
/// Shows the current phase card with SF Symbol, day-of-cycle indicator,
/// next-prediction date, and a short stress-correlation note. All cards
/// use `WatchDesignTokens` surfaces, radii, and ink colours.
struct WatchCycleView: View {
    @State private var viewModel = WatchCycleViewModel()

    @ScaledMetric(relativeTo: .body) private var bodyScale: CGFloat = 1
    @ScaledMetric(relativeTo: .caption2) private var caption2Scale: CGFloat = 1
    @ScaledMetric(relativeTo: .footnote) private var footnoteScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title) private var titleScale: CGFloat = 1
    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                if let data = viewModel.cycleData {
                    phaseCard(data)
                    dayIndicator(data)
                    if let prediction = data.nextPrediction {
                        predictionRow(prediction)
                    }
                    if let note = viewModel.stressCorrelationForToday() {
                        correlationNote(note)
                    }
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("Cycle")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Phase card

    private func phaseCard(_ data: CycleData) -> some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(WatchDesignTokens.accentSoft)
                    .frame(width: 40, height: 40)
                Image(systemName: data.currentPhase.icon)
                    .font(.system(size: 16, weight: .semibold)) // dated exception 2026-09-05: icon inside fixed 40pt circular well
                    .foregroundStyle(WatchDesignTokens.accentStrong)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("CURRENT PHASE")
                    .font(.system(size: 7.5 * caption2Scale, weight: .semibold, design: .monospaced))
                    .tracking(0.08 * 7.5)
                    .foregroundStyle(WatchDesignTokens.muted)
                Text(data.currentPhase.displayName)
                    .font(.system(size: 14 * footnoteScale, weight: .semibold, design: .rounded))
                    .tracking(-0.01 * 14)
                    .foregroundStyle(WatchDesignTokens.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Day indicator

    private func dayIndicator(_ data: CycleData) -> some View {
        HStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("DAY \(data.dayOfCycle)")
                    .font(.system(size: 18 * bodyScale, weight: .bold, design: .rounded).monospacedDigit())
                    .tracking(-0.02 * 18)
                    .foregroundStyle(WatchDesignTokens.ink)
                Text("OF \(data.cycleLength)")
                    .font(.system(size: 8 * caption2Scale, weight: .semibold, design: .monospaced))
                    .tracking(0.08 * 8)
                    .foregroundStyle(WatchDesignTokens.muted)
            }
            Spacer(minLength: 0)
            Text("Next: \(viewModel.predictNextPhase().displayName)")
                .font(.system(size: 10 * caption2Scale, weight: .medium, design: .rounded))
                .foregroundStyle(WatchDesignTokens.muted)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Prediction

    private func predictionRow(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 11 * caption2Scale, weight: .semibold))
                .foregroundStyle(WatchDesignTokens.muted)
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 13 * footnoteScale, weight: .semibold, design: .rounded))
                .tracking(-0.01 * 13)
                .foregroundStyle(WatchDesignTokens.ink)
            Spacer(minLength: 0)
            Text("NEXT")
                .font(.system(size: 7 * caption2Scale, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Correlation note

    private func correlationNote(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 9 * caption2Scale, weight: .semibold))
                    .foregroundStyle(WatchDesignTokens.accentStrong)
                Text("STRESS NOTE")
                    .font(.system(size: 7.5 * caption2Scale, weight: .semibold, design: .monospaced))
                    .tracking(0.08 * 7.5)
                    .foregroundStyle(WatchDesignTokens.accentStrong)
            }
            Text(note)
                .font(.system(size: 9.5 * caption2Scale, weight: .regular, design: .default))
                .foregroundStyle(WatchDesignTokens.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.accentSoft)
        )
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            Image(systemName: "drop")
                .font(.system(size: 28 * titleScale, weight: .regular))
                .foregroundStyle(WatchDesignTokens.mutedSystem)
            Text("No cycle logged")
                .font(.system(size: 12 * footnoteScale, weight: .semibold, design: .default))
                .foregroundStyle(WatchDesignTokens.ink)
            Text("Log the start of your cycle to see predictions and stress correlations.")
                .font(.system(size: 9.5 * caption2Scale, weight: .regular, design: .default))
                .foregroundStyle(WatchDesignTokens.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Button {
                viewModel.logCycleStart(Date())
            } label: {
                Text("Log Today")
                    .font(.system(size: 11 * caption2Scale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 32)
                    .background(
                        Capsule(style: .continuous)
                            .fill(WatchDesignTokens.accentStrong)
                    )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 10)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchCycleView()
    }
}
#endif
