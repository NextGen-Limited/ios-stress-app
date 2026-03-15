import Charts
import SwiftUI

struct BeforeAfterChart: View {
    let beforeValue: Double
    let afterValue: Double

    private var chartData: [(label: String, value: Double, color: Color)] {
        [
            ("Before", beforeValue, .stressHigh),
            ("After", afterValue, afterValue > beforeValue ? .stressRelaxed : .stressHigh)
        ]
    }

    private var maxValue: Double {
        max(beforeValue, afterValue) * 1.2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before / After")
                .font(Typography.headline)

            HStack(alignment: .bottom, spacing: 16) {
                Chart(chartData, id: \.label) { item in
                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(8)
                }
                .chartYScale(domain: 0...maxValue)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text("\(Int(label == "Before" ? beforeValue : afterValue)) ms")
                                    .font(Typography.caption1)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(width: 60, height: 150)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

#Preview {
    BeforeAfterChart(beforeValue: 45, afterValue: 65)
        .padding()
}
