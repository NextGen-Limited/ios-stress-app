import SwiftUI

struct StressSource: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

/// Semi-donut (180° arc) stress sources chart with 6-category legend grid
struct StressSourcesDonutChart: View {
    let sources: [StressSource]
    let totalDays: Int

    init(sources: [StressSource], totalDays: Int = 30) {
        self.sources = sources
        self.totalDays = totalDays
    }

    private let ringWidth: CGFloat = 24

    // Only sources with nonzero percentage participate in the arc
    private var activeSources: [StressSource] { sources.filter { $0.percentage > 0 } }
    private var total: Double { activeSources.reduce(0) { $0 + $1.percentage } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title row
            HStack {
                Text("Stress Sources")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("Last \(totalDays) days")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            // Semi-donut centered
            ZStack {
                semiDonutSegments
                centerLabel
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)

            // 6-item legend in 3-column grid
            legendGrid
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }

    // MARK: - Semi-donut arc (upper 180°, from 180° to 0°)

    @ViewBuilder
    private var semiDonutSegments: some View {
        if activeSources.isEmpty {
            SemiArcShape(startDeg: 0, endDeg: 180, ringWidth: ringWidth)
                .fill(Color.secondary.opacity(0.15))
        } else {
            ForEach(activeSources) { source in
                let start = semiStartDeg(for: source)
                let end = semiEndDeg(for: source)
                SemiArcShape(startDeg: start, endDeg: end, ringWidth: ringWidth)
                    .fill(source.color)
            }
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text("Last")
                .font(Typography.caption2)
                .foregroundColor(.secondary)
            Text("\(totalDays) days")
                .font(Typography.caption1.bold())
                .foregroundColor(.primary)
        }
        .offset(y: 30) // shift toward base of semi-circle
    }

    /// Maps source percentage → start degree in the 180° upper arc (0° = left, 180° = right)
    private func semiStartDeg(for source: StressSource) -> Double {
        guard let index = activeSources.firstIndex(where: { $0.id == source.id }) else { return 0 }
        let prevTotal = activeSources[0..<index].reduce(0) { $0 + $1.percentage }
        return (prevTotal / total) * 180
    }

    private func semiEndDeg(for source: StressSource) -> Double {
        guard let index = activeSources.firstIndex(where: { $0.id == source.id }) else { return 0 }
        let currentTotal = activeSources[0...index].reduce(0) { $0 + $1.percentage }
        return (currentTotal / total) * 180
    }

    // MARK: - 6-item legend in 3×2 grid

    private var legendGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(sources) { source in
                HStack(spacing: 6) {
                    Circle()
                        .fill(source.color)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(source.name)
                            .font(Typography.caption2)
                            .foregroundColor(.primary)
                        if source.percentage > 0 {
                            Text("\(Int(source.percentage))%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SemiArcShape

/// Draws a ring arc segment within the upper 180° semicircle.
/// startDeg and endDeg are in 0–180 range (0 = leftmost, 180 = rightmost).
struct SemiArcShape: Shape {
    let startDeg: Double
    let endDeg: Double
    let ringWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY) // base at bottom
        let outerRadius = min(rect.width, rect.height * 2) / 2 - ringWidth / 2
        let innerRadius = outerRadius - ringWidth

        // Convert 0–180 range to actual angles: 180° (left) → 0° (right) in standard coords
        let startAngle = Angle.degrees(180 - endDeg)
        let endAngle = Angle.degrees(180 - startDeg)

        path.addArc(center: center, radius: outerRadius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

#Preview {
    StressSourcesDonutChart(
        sources: [
            StressSource(name: "Finance", percentage: 35, color: Color(hex: "#00BFA5")),
            StressSource(name: "Relationship", percentage: 15, color: Color(hex: "#FF9800")),
            StressSource(name: "Health", percentage: 50, color: Color(hex: "#FFD60A")),
            StressSource(name: "Family", percentage: 0, color: .stressRelaxed),
            StressSource(name: "Work", percentage: 0, color: .primaryBlue),
            StressSource(name: "Environment", percentage: 0, color: .stressSevere)
        ]
    )
    .padding()
    .background(Color.backgroundLight)
}
