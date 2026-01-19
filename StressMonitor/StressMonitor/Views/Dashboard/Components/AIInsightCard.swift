import SwiftUI

struct AIInsight: Sendable {
    let title: String
    let message: String
    let actionTitle: String?
    let trendData: [Double]?
}

struct AIInsightCard: View {
    let insight: AIInsight
    var onTapAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if let actionTitle = insight.actionTitle {
                Button(action: { onTapAction?() }) {
                    HStack {
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primaryBlue)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.primaryBlue)
                .font(.title3)

            Text("AI Insight")
                .font(.headline)

            Spacer()

            if let trendData = insight.trendData, !trendData.isEmpty {
                MiniSparkline(data: trendData)
                    .frame(width: 60, height: 30)
            }
        }
    }
}

struct MiniSparkline: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let normalized = normalize(data: data)
            let points = zip(normalized.indices, normalized).map { index, value in
                CGPoint(
                    x: CGFloat(index) / CGFloat(max(1, normalized.count - 1)) * geometry.size.width,
                    y: geometry.size.height - (value * geometry.size.height)
                )
            }

            Path { path in
                if let first = points.first {
                    path.move(to: first)
                }
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.primaryBlue, lineWidth: 2)
        }
    }

    private func normalize(data: [Double]) -> [Double] {
        guard let min = data.min(), let max = data.max(), max > min else { return data }
        let range = max - min
        return data.map { ($0 - min) / range }
    }
}

#Preview {
    VStack(spacing: 16) {
        AIInsightCard(insight: AIInsight(
            title: "High Stress Detected",
            message: "Your stress is elevated. Consider a breathing exercise.",
            actionTitle: "Start Breathing",
            trendData: [0.3, 0.5, 0.7, 0.6, 0.8, 0.9]
        ))

        AIInsightCard(insight: AIInsight(
            title: "Great Recovery",
            message: "Your HRV is excellent today. Keep up the good work!",
            actionTitle: nil,
            trendData: nil
        ))
    }
    .padding()
}
