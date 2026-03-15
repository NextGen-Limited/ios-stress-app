import Charts
import SwiftUI

/// Mini line chart for metric cards using SwiftUI Charts
struct MiniLineChartView: View {
    let dataPoints: [Double]
    let color: Color
    var showGradient: Bool = true

    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if showGradient {
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .frame(height: 40)
        }
    }
}

#Preview("Mini Line Chart") {
    VStack(spacing: 20) {
        MiniLineChartView(
            dataPoints: [45, 52, 48, 55, 50, 58, 62],
            color: .hrvAccent
        )
        .frame(width: 100)

        MiniLineChartView(
            dataPoints: [72, 68, 70, 65, 68, 72, 70],
            color: .heartRateAccent
        )
        .frame(width: 100)

        MiniLineChartView(
            dataPoints: [20, 35, 28, 42, 38, 45, 52],
            color: .stressMild
        )
        .frame(width: 100)
    }
    .padding()
    .background(Color.oledCardBackground)
}
