import SwiftUI

/// Stress Sources card with donut chart visualization
/// Figma: White card with donut chart showing stress sources breakdown
struct StressSourcesCard: View {
    // MARK: - Data Model

    struct StressSourceData: Identifiable {
        let id = UUID()
        let name: String
        let percentage: Double
        let color: Color
        let icon: String
    }

    // MARK: - Properties

    let sources: [StressSourceData]
    let totalDays: Int

    // MARK: - Init

    init(sources: [StressSourceData]? = nil, totalDays: Int = 30) {
        // Default sample data if none provided
        if let sources = sources {
            self.sources = sources
        } else {
            self.sources = [
                .init(name: "Finance", percentage: 0.35, color: Color(hex: "#66CDAA"), icon: "dollarsign.circle.fill"),
                .init(name: "Relationship", percentage: 0.50, color: Color(hex: "#F1AE00"), icon: "heart.fill"),
                .init(name: "Health", percentage: 0.15, color: Color(hex: "#FFD700"), icon: "cross.case.fill"),
                .init(name: "Family", percentage: 0, color: Color(hex: "#87CEEB"), icon: "house.fill"),
                .init(name: "Work", percentage: 0, color: Color(hex: "#9370DB"), icon: "briefcase.fill"),
                .init(name: "Environment", percentage: 0, color: Color(hex: "#90EE90"), icon: "leaf.fill")
            ]
        }
        self.totalDays = totalDays
    }

    // Active sources (non-zero) for donut chart
    private var activeSources: [StressSourceData] {
        sources.filter { $0.percentage > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            donutChartSection
            legendGrid
        }
        .padding(Spacing.settingsCardPadding)
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.settingsCardRadius))
        .shadow(AppShadow.settingsCard)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stress sources")
                .font(.custom("Lato-Bold", size: 18))
                .kerning(-0.27)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("Last \(totalDays) days")
                .font(.custom("Lato-Bold", size: 13.97))
                .kerning(-0.21)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText.opacity(0.6))
        }
    }

    // MARK: - Donut Chart

    private var donutChartSection: some View {
        ZStack {
            ForEach(1...3, id: \.self) { i in
                Ellipse()
                    .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.1), lineWidth: 1)
                    .frame(width: 200 - CGFloat(i * 20), height: 200 - CGFloat(i * 20))
            }

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outerRadius = min(size.width, size.height) / 2 - 10
                let innerRadius = outerRadius - 22

                let backgroundPath = Path { path in
                    path.addArc(center: center, radius: outerRadius - 11, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                    path.addArc(center: center, radius: innerRadius, startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
                    path.closeSubpath()
                }
                context.fill(backgroundPath, with: .color(Color(hex: "#E5E5EA")))

                let total = activeSources.reduce(0) { $0 + $1.percentage }
                var startAngle = -90.0

                for source in activeSources {
                    let angle = (source.percentage / total) * 360
                    let endAngle = startAngle + angle

                    let segmentPath = Path { path in
                        path.addArc(center: center, radius: outerRadius - 11, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
                        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(endAngle), endAngle: .degrees(startAngle), clockwise: true)
                        path.closeSubpath()
                    }
                    context.fill(segmentPath, with: .color(source.color))
                    startAngle = endAngle
                }
            }
            .frame(width: 200, height: 200)

            VStack(spacing: 2) {
                Text("\(Int(totalPercentage * 100))%")
                    .font(.custom("Lato-Bold", size: 16))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Total")
                    .font(.custom("Lato-Regular", size: 12))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var totalPercentage: Double {
        activeSources.reduce(0) { $0 + $1.percentage }
    }

    // MARK: - Legend Grid

    private var legendGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(65), spacing: 9), count: 3),
            spacing: 19
        ) {
            ForEach(sources) { source in
                legendItem(label: source.name, color: source.color)
            }
        }
    }

    private func legendItem(label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 21.5, height: 21.5)

            Text(label)
                .font(.custom("Lato-Bold", size: 11.99))
                .foregroundStyle(Color(hex: "#363636"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 65, height: 42)
    }
}

// MARK: - Percentage Labels View

private struct PercentageLabelsView: View {
    let sources: [StressSourcesCard.StressSourceData]

    var body: some View {
        let total = sources.reduce(0) { $0 + $1.percentage }
        var accumulatedAngle = -90.0

        ForEach(sources) { source in
            labelView(for: source, total: total, accumulatedAngle: &accumulatedAngle)
        }
    }

    @ViewBuilder
    private func labelView(for source: StressSourcesCard.StressSourceData, total: Double, accumulatedAngle: inout Double) -> some View {
        let angle = (source.percentage / total) * 360
        let midAngle = accumulatedAngle + (angle / 2)
        let radius: CGFloat = 70

        if source.percentage >= 0.10 {
            let labelPosition = CGPoint(
                x: cos(midAngle * .pi / 180) * radius,
                y: sin(midAngle * .pi / 180) * radius
            )

            Text("\(Int(source.percentage * 100))%")
                .font(.custom("Lato-Bold", size: 14))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .offset(x: labelPosition.x, y: labelPosition.y)
        }

    }
}

#Preview("StressSourcesCard") {
    StressSourcesCard()
        .padding()
        .background(Color.Wellness.adaptiveBackground)
}
