import SwiftUI

/// Pattern insights section for the Trends redesign.
///
/// Presents Ripple as the analyst: "Ripple spotted these patterns" with
/// tinted cards per insight type. Descriptions can include HRV/time data,
/// but stress scores remain non-numeric across the Trends UI.
struct PatternInsightsSection: View {
    let insights: [PatternInsight]

    private var displayInsights: [PatternInsight] {
        if insights.isEmpty {
            return [
                PatternInsight(
                    icon: "☀️",
                    title: "Afternoon Dips",
                    description: "Your stress tends to rise during afternoon work blocks. Consider a short walk or breathing reset."
                ),
                PatternInsight(
                    icon: "🌙",
                    title: "Great Recovery",
                    description: "Your recovery improves after longer sleep windows. Ripple will keep watching this pattern."
                )
            ]
        }
        return Array(insights.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 10) {
                ForEach(Array(displayInsights.enumerated()), id: \.offset) { index, insight in
                    PatternInsightRow(
                        insight: insight,
                        accent: accent(for: index, icon: insight.icon)
                    )
                }
            }
        }
        .trendsGlassCard()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🔍")
                .font(.system(size: 22))
                .frame(width: 38, height: 38)
                .background(TrendsPalette.rippleBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Pattern Insights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Ripple spotted these patterns")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.48))
            }

            Spacer()
        }
    }

    private func accent(for index: Int, icon: String) -> Color {
        if icon.contains("☀️") || icon.contains("📈") { return Color(hex: "#FFB74D") }
        if icon.contains("🌙") || icon.contains("💤") { return Color(hex: "#81C784") }
        if icon.contains("🏃") { return TrendsPalette.rippleBlue }
        return [Color(hex: "#FFB74D"), Color(hex: "#81C784"), TrendsPalette.rippleBlue][index % 3]
    }
}

private struct PatternInsightRow: View {
    let insight: PatternInsight
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.94))

                Text(insight.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.56))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct PatternInsightsSection_Previews: PreviewProvider {
    static var previews: some View {
        PatternInsightsSection(insights: [])
            .padding()
            .background(TrendsPalette.darkCanvas)
    }
}
