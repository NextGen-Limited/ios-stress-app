import SwiftUI

struct InsightCard: View {
    let insight: PatternInsight

    var body: some View {
        HStack(spacing: 12) {
            Text(insight.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)

                Text(insight.description)
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
