import SwiftUI

/// Trends-specific Stress Sources card matching the Ripple dark-canvas redesign.
///
/// Unlike the shared Dashboard `StressSourcesCard`, this uses emoji icons,
/// tinted source rows, and gradient progress bars on glass cards.
struct TrendsStressSourcesCard: View {
    struct Source: Identifiable {
        let id = UUID()
        let name: String
        let percentage: Double
        let color: Color
        let emoji: String
    }

    let sources: [Source]

    private var activeSources: [Source] {
        sources.filter { $0.percentage > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 12) {
                ForEach(activeSources) { source in
                    sourceRow(source)
                }
            }
        }
        .trendsGlassCard()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stress Sources")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("What's contributing this week")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private func sourceRow(_ source: Source) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text(source.emoji)
                    .font(.system(size: 22))
                    .frame(width: 38, height: 38)
                    .background(source.color.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(source.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text("\(Int(source.percentage))%")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(source.color)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [source.color.opacity(0.55), source.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, proxy.size.width * min(source.percentage / 100, 1)))
                        .shadow(color: source.color.opacity(0.28), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 9)
        }
        .padding(12)
        .background(source.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(source.color.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TrendsStressSourcesCard_Previews: PreviewProvider {
    static var previews: some View {
        TrendsStressSourcesCard(sources: [
            .init(name: "Finance", percentage: 35, color: Color(hex: "#F6C453"), emoji: "💰"),
            .init(name: "Relationship", percentage: 15, color: Color(hex: "#B388FF"), emoji: "❤️"),
            .init(name: "Health", percentage: 50, color: Color(hex: "#FFB74D"), emoji: "🏥")
        ])
        .padding()
        .background(TrendsPalette.darkCanvas)
    }
}
