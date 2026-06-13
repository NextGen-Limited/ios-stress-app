import SwiftUI

/// HRV before/after bar chart with gradient bars, on-top values, and improvement summary.
/// Designed for the dark Ripple breathing summary screen.
struct BeforeAfterChart: View {
    let beforeValue: Double
    let afterValue: Double

    private var maxValue: Double {
        max(beforeValue, afterValue) * 1.25
    }

    private var improvement: Double {
        afterValue - beforeValue
    }

    private var percentageImprovement: Double {
        beforeValue > 0 ? (improvement / beforeValue) * 100 : 0
    }

    var body: some View {
        VStack(spacing: 20) {
            // Improvement summary
            HStack(spacing: 4) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 13, design: .rounded))
                Text("+\(Int(improvement))ms · +\(Int(percentageImprovement))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color(hex: "#81C784"))

            // Bars
            HStack(alignment: .bottom, spacing: 36) {
                barColumn(
                    label: "Before",
                    value: beforeValue,
                    gradient: LinearGradient(
                        colors: [Color(hex: "#FF8A80"), Color(hex: "#E53935")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                barColumn(
                    label: "After",
                    value: afterValue,
                    gradient: LinearGradient(
                        colors: [Color(hex: "#A5D6A7"), Color(hex: "#43A047")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func barColumn(label: String, value: Double, gradient: LinearGradient) -> some View {
        VStack(spacing: 8) {
            // Value on top
            Text("\(Int(value))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityLabel("\(label) \(Int(value)) milliseconds")

            // Bar
            RoundedRectangle(cornerRadius: 8)
                .fill(gradient)
                .frame(width: 48, height: max(4, CGFloat(value / maxValue) * 100))

            // Label below
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }
}

#Preview {
    BeforeAfterChart(beforeValue: 45, afterValue: 61)
        .padding()
        .background(HomeCharacterDesignTokens.darkCanvas)
}
