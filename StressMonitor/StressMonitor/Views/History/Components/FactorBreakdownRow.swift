import SwiftUI

/// One row of the multi-factor stress breakdown: icon, factor name, normalized bar,
/// raw value, and an optional confidence badge.
///
/// When `value` is nil the factor was unavailable for this measurement; the row renders
/// a greyed-out bar and "—" value rather than dropping silently.
struct FactorBreakdownRow: View {
    enum Factor: Hashable {
        case hrv, heartRate, sleep, activity, recovery

        var displayName: String {
            switch self {
            case .hrv:        return "HRV"
            case .heartRate:  return "Heart Rate"
            case .sleep:      return "Sleep"
            case .activity:   return "Activity"
            case .recovery:   return "Recovery"
            }
        }

        var icon: String {
            switch self {
            case .hrv:        return "waveform.path.ecg"
            case .heartRate:  return "heart.fill"
            case .sleep:      return "moon.zzz.fill"
            case .activity:   return "figure.run"
            case .recovery:   return "leaf.fill"
            }
        }

        var tint: Color {
            switch self {
            case .hrv:        return .stressRelaxed
            case .heartRate:  return .heartRateAccent
            case .sleep:      return .settingsIconPurple
            case .activity:   return .stressHigh
            case .recovery:   return .primaryGreen
            }
        }
    }

    let factor: Factor
    /// Normalized stress contribution 0–1 (nil = factor unavailable).
    var value: Double?
    /// Optional human-readable raw input (e.g. "52 ms", "68 bpm").
    var detailText: String? = nil
    var confidence: Double? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(factor.tint.opacity(value == nil ? 0.08 : 0.16))
                Image(systemName: factor.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(value == nil ? Color.Wellness.adaptiveSecondaryText : factor.tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(factor.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                    if let confidence {
                        confidenceBadge(confidence)
                    }

                    Spacer()

                    Text(valueText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(value == nil
                            ? Color.Wellness.adaptiveSecondaryText
                            : Color.Wellness.adaptivePrimaryText)
                }

                progressBar
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(factor.displayName). \(value == nil ? "Not available" : detailText ?? valueText)")
    }

    private var valueText: String {
        if let value {
            return "\(Int((value * 100).rounded()))%"
        }
        return "—"
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
                Capsule()
                    .fill(barFill)
                    .frame(width: proxy.size.width * barWidth)
            }
        }
        .frame(height: 6)
    }

    private var barFill: Color {
        value == nil
            ? Color.Wellness.adaptiveSecondaryText.opacity(0.35)
            : factor.tint.opacity(0.8)
    }

    private var barWidth: Double {
        guard let value else { return 0.18 }
        return min(1, max(0.03, value))
    }

    private func confidenceBadge(_ confidence: Double) -> some View {
        let label: String
        switch confidence {
        case 0.8...:    label = "High"
        case 0.5..<0.8: label = "Med"
        default:        label = "Low"
        }
        return Text(label)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.Wellness.adaptiveSecondaryText.opacity(0.12), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 14) {
        FactorBreakdownRow(factor: .hrv, value: 0.72, detailText: "52 ms", confidence: 0.85)
        FactorBreakdownRow(factor: .heartRate, value: 0.41, detailText: "68 bpm", confidence: 0.62)
        FactorBreakdownRow(factor: .sleep, value: nil)
        FactorBreakdownRow(factor: .activity, value: 0.30, detailText: "45 min", confidence: 0.4)
        FactorBreakdownRow(factor: .recovery, value: nil)
    }
    .padding()
    .background(Color.appBackground)
}
