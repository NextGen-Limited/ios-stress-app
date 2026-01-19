import SwiftUI

struct BeforeAfterChart: View {
    let beforeValue: Double
    let afterValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before / After")
                .font(Typography.headline)

            HStack(alignment: .bottom, spacing: 16) {
                VStack(spacing: 8) {
                    BarView(
                        value: beforeValue,
                        maxValue: max(beforeValue, afterValue) * 1.2,
                        color: .stressHigh
                    )

                    Text("\(Int(beforeValue)) ms")
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 8) {
                    BarView(
                        value: afterValue,
                        maxValue: max(beforeValue, afterValue) * 1.2,
                        color: afterValue > beforeValue ? .stressRelaxed : .stressHigh
                    )

                    Text("\(Int(afterValue)) ms")
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

struct BarView: View {
    let value: Double
    let maxValue: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(height: geometry.size.height * (value / maxValue))

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
            }
        }
        .frame(width: 60, height: 150)
    }
}
