import SwiftUI

struct HistoryRowView: View {
    let measurement: StressMeasurement

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(measurement.timestamp))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text(formatDate(measurement.timestamp))
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(measurement.stressLevel))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(colorForStress(measurement.stressLevel))

                    Text("/100")
                        .font(Typography.caption1)
                        .foregroundColor(.secondary)
                }

                Text("HRV: \(Int(measurement.hrv))ms")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.05))
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func colorForStress(_ level: Double) -> Color {
        switch level {
        case 0...25: return .stressRelaxed
        case 26...50: return .stressMild
        case 51...75: return .stressModerate
        default: return .stressHigh
        }
    }
}
