import SwiftUI

// MARK: - WatchBioAgeCardView

/// Compact card summarising a BioAge estimate.
///
/// Shows:
///  - Big "estimated age" number in tier-coloured ink
///  - Difference label ("-3 yrs", "+2 yrs") with trend SF Symbol
///  - Confidence bar (0–100%)
///  - Optional celebratory accent ring when `isCelebratory`
///
/// The card mirrors the iOS BioAge tile aesthetic: light surface, hairline
/// divider, accent-strong emphasis on the headline number. Uses the
/// `BioAgeResult` model from `Models/BioAgeResult.swift`.
struct WatchBioAgeCardView: View {
    let result: BioAgeResult
    var showsConfidence: Bool = true

    private let cardHeight: CGFloat = 88

    var body: some View {
        HStack(spacing: 10) {
            ageBlock
            Divider()
                .frame(width: WatchDesignTokens.hairlineThickness)
                .background(WatchDesignTokens.separator)
            trendBlock
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.sm)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: cardHeight)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                        .stroke(
                            result.isCelebratory ? WatchDesignTokens.accentStrong.opacity(0.6) : .clear,
                            lineWidth: result.isCelebratory ? 1.2 : 0
                        )
                )
        )
        .accessibilityElement()
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Age block

    private var ageBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("BIO AGE")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                .tracking(0.05 * 7.5)
                .foregroundStyle(WatchDesignTokens.muted)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(result.estimatedAge)")
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .tracking(-0.02 * 30)
                    .foregroundStyle(ageColor)
                Text("yrs")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchDesignTokens.muted)
            }
            if showsConfidence {
                confidenceBar
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Confidence

    private var confidenceBar: some View {
        let pct = min(max(result.confidence, 0), 1)
        return VStack(alignment: .leading, spacing: 2) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(WatchDesignTokens.separator)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(WatchDesignTokens.accent)
                        .frame(width: max(proxy.size.width * pct, 4), height: 3)
                }
            }
            .frame(height: 3)
            Text("\(Int(pct * 100))% CONF")
                .font(.system(size: 7, weight: .regular, design: .monospaced))
                .tracking(0.03 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
    }

    // MARK: - Trend block

    private var trendBlock: some View {
        VStack(spacing: 2) {
            Image(systemName: result.trend.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(trendColor)
            Text(result.differenceLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(trendColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("VS CHRONO")
                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                .tracking(0.04 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .frame(width: 70)
    }

    // MARK: - Helpers

    private var ageColor: Color {
        if result.isCelebratory { return WatchDesignTokens.accentStrong }
        return WatchDesignTokens.ink
    }

    private var trendColor: Color {
        switch result.difference {
        case ..<0:   return StressCategory.relaxed.color   // younger = good
        case 0:      return WatchDesignTokens.mutedSystem
        default:     return StressCategory.high.color       // older = warning
        }
    }

    private var accessibilitySummary: String {
        let dir = result.difference < 0 ? "younger than" : (result.difference > 0 ? "older than" : "same as")
        return "Biological age \(result.estimatedAge) years, \(dir) chronological \(result.chronologicalAge). \(result.differenceLabel). \(Int(result.confidence * 100)) percent confidence."
    }
}

#if DEBUG
#Preview("BioAge card") {
    VStack(spacing: 10) {
        WatchBioAgeCardView(
            result: BioAgeResult(
                estimatedAge: 27,
                chronologicalAge: 30,
                trend: .improving,
                confidence: 0.78
            )
        )
        WatchBioAgeCardView(
            result: BioAgeResult(
                estimatedAge: 34,
                chronologicalAge: 30,
                trend: .declining,
                confidence: 0.62
            )
        )
    }
    .padding()
    .background(WatchDesignTokens.canvas)
}
#endif
