import SwiftUI

struct StressSource: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

struct StressSourcesDonutChart: View {
    let sources: [StressSource]
    let totalDays: Int

    init(sources: [StressSource], totalDays: Int = 30) {
        self.sources = sources
        self.totalDays = totalDays
    }

    private let ringWidth: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stress Sources")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("Last 30 days")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                // Donut chart
                ZStack {
                    donutSegments

                    // Center text
                    VStack(spacing: 2) {
                        Text("\(totalDays)")
                            .font(Typography.dataMedium)
                            .foregroundColor(.primary)
                        Text("days")
                            .font(Typography.caption1)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 120)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sources) { source in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(source.color)
                                .frame(width: 8, height: 8)

                            Text(source.name)
                                .font(Typography.caption1)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(Int(source.percentage))%")
                                .font(Typography.caption1)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    @ViewBuilder
    private var donutSegments: some View {
        let total = sources.reduce(0) { $0 + $1.percentage }

        ForEach(sources) { source in
            let startAngle = startAngleFor(source: source, total: total)
            let endAngle = endAngleFor(source: source, total: total)

            ArcShape(startAngle: startAngle, endAngle: endAngle, ringWidth: ringWidth)
                .fill(source.color)
        }
    }

    private func startAngleFor(source: StressSource, total: Double) -> Double {
        let index = sources.firstIndex(where: { $0.id == source.id }) ?? 0
        let previousTotal = sources[0..<index].reduce(0) { $0 + $1.percentage }
        return (previousTotal / total) * 360 - 90
    }

    private func endAngleFor(source: StressSource, total: Double) -> Double {
        let index = sources.firstIndex(where: { $0.id == source.id }) ?? 0
        let currentTotal = sources[0...index].reduce(0) { $0 + $1.percentage }
        return (currentTotal / total) * 360 - 90
    }
}

struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double
    let ringWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - ringWidth / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: radius - ringWidth,
            startAngle: .degrees(endAngle),
            endAngle: .degrees(startAngle),
            clockwise: true
        )
        path.closeSubpath()

        return path
    }
}

#Preview {
    StressSourcesDonutChart(
        sources: [
            StressSource(name: "Work", percentage: 50, color: .primaryBlue),
            StressSource(name: "Finance", percentage: 30, color: Color(hex: "#00BFA5")),
            StressSource(name: "Relationship", percentage: 15, color: Color(hex: "#FF9800")),
            StressSource(name: "Health", percentage: 5, color: Color(hex: "#FFD60A"))
        ]
    )
    .padding()
}
