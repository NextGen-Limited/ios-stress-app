import SwiftUI

struct CircularStressIndicatorView: View {
    let icon: String
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: min(percentage, 100) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: percentage)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundColor(color)
                    Text("\(Int(percentage))%")
                        .font(Typography.caption1.bold())
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 60, height: 60)

            Text(label)
                .font(Typography.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CircularStressIndicatorView(icon: "leaf.fill", label: "Relaxed", percentage: 57, color: .stressRelaxed)
        CircularStressIndicatorView(icon: "circle.fill", label: "Neutral", percentage: 27, color: .stressMild)
        CircularStressIndicatorView(icon: "triangle.fill", label: "Working", percentage: 15, color: .stressModerate)
        CircularStressIndicatorView(icon: "square.fill", label: "Stressed", percentage: 21, color: .stressHigh)
    }
    .padding()
}
