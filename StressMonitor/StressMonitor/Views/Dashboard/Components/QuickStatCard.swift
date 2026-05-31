import SwiftUI

struct QuickStatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let tintColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tintColor)
                .frame(width: 44, height: 44)
                .background(tintColor.opacity(0.15))
                .cornerRadius(12)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    HStack(spacing: 12) {
        QuickStatCard(
            icon: "heart.fill",
            value: "45",
            unit: "ms",
            label: "Today's HRV",
            tintColor: .red
        )

        QuickStatCard(
            icon: "chart.xyaxis.lines",
            value: "↑",
            unit: "",
            label: "7-Day",
            tintColor: .stressRelaxed
        )

        QuickStatCard(
            icon: "scale.3d",
            value: "35-55",
            unit: "",
            label: "Baseline",
            tintColor: .primaryBlue
        )
    }
    .padding()
}
