import SwiftUI

/// Two-bar vertical comparison of pre- and post-session HRV.
///
/// Renders the delta (e.g. "+14 ms") in `stressRelaxed` when positive (improvement),
/// `stressHigh` when negative. Nil-safe: a nil value renders an empty bar with "—".
struct BeforeAfterHRVChart: View {
    var before: Double?
    var after: Double?

    private let barWidth: CGFloat = 56

    var body: some View {
        VStack(spacing: 16) {
            barsRow
            deltaLabel
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(deltaAccessibility)
    }

    private var barsRow: some View {
        let maxValue = max(before ?? 1, after ?? 1, 1)

        return GeometryReader { proxy in
            let availableHeight = proxy.size.height
            HStack(alignment: .bottom, spacing: 32) {
                bar(
                    label: "Before",
                    value: before,
                    height: before.map { availableHeight * ($0 / maxValue) } ?? 0,
                    tint: HomeCharacterDesignTokens.Ember.accent
                )
                bar(
                    label: "After",
                    value: after,
                    height: after.map { availableHeight * ($0 / maxValue) } ?? 0,
                    tint: .stressRelaxed
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 140)
    }

    private func bar(label: String, value: Double?, height: CGFloat, tint: Color) -> some View {
        VStack(spacing: 8) {
            Text(value.map { "\(Int($0.rounded())) ms" } ?? "—")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .monospacedDigit()

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(value == nil ? 0.2 : 0.85))
                .frame(width: barWidth, height: max(4, height))

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    private var deltaLabel: some View {
        Group {
            if let delta = computedDelta {
                HStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(delta >= 0 ? "+" : "")\(Int(delta.rounded())) ms")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(delta >= 0 ? Color.stressRelaxed : Color.stressHigh)
            } else {
                Text("HRV comparison unavailable")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
    }

    private var computedDelta: Double? {
        guard let before, let after else { return nil }
        return after - before
    }

    private var deltaAccessibility: String {
        guard let delta = computedDelta else { return "HRV comparison unavailable" }
        let direction = delta >= 0 ? "improved by" : "decreased by"
        return "Heart rate variability \(direction) \(Int(abs(delta).rounded())) milliseconds"
    }
}

#Preview {
    BeforeAfterHRVChart(before: 52, after: 66)
        .padding()
        .background(HomeCharacterDesignTokens.darkCanvas)
}
