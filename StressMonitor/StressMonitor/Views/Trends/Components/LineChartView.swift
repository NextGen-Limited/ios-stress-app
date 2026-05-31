import Charts
import SwiftUI

// MARK: - Chart Time Range Selector

/// Time range options for the stress chart
/// Note: Separate from TimeRange in HistoryViewModel to avoid conflicts
enum ChartTimeRange: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
}

// MARK: - Line Chart View

/// Line chart with area fill using SwiftUI Charts
/// Supports touch interaction via chart overlay
struct LineChartView: View {
    let dataPoints: [ChartDataPoint]
    let accentColor: Color
    let showGrid: Bool
    var showYAxisLabels: Bool = false

    @State private var selectedPoint: ChartDataPoint?

    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(accentColor)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(accentColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Value", selected.value)
                )
                .foregroundStyle(accentColor)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            if showGrid {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.1))
                }
            }
        }
        .chartYAxis {
            if showGrid || showYAxisLabels {
                AxisMarks(values: [0, 50, 100, 150]) { value in
                    AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.1))

                    if showYAxisLabels {
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectedPoint = findNearestPoint(at: value.location, in: geometry.size, proxy: proxy)
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .chartYScale(domain: 0...160)
    }

    private func findNearestPoint(at location: CGPoint, in size: CGSize, proxy: ChartProxy) -> ChartDataPoint? {
        guard let date: Date = proxy.value(atX: location.x) else { return nil }

        return dataPoints.min { point1, point2 in
            let dist1 = abs(point1.date.timeIntervalSince(date))
            let dist2 = abs(point2.date.timeIntervalSince(date))
            return dist1 < dist2
        }
    }
}

#Preview("Line Chart") {
    LineChartView(
        dataPoints: [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 86400), value: 45),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 86400), value: 52),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 86400), value: 48),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 86400), value: 55),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 86400), value: 50),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 86400), value: 58),
            ChartDataPoint(date: Date(), value: 62)
        ],
        accentColor: .stressMild,
        showGrid: true,
        showYAxisLabels: true
    )
    .frame(height: 200)
    .padding()
}
