import SwiftUI
import SwiftData

struct WeeklyHeatmapView: View {
    let measurements: [StressMeasurement]

    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Timeline")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("Last 7 days")
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    // Day labels column
                    VStack(alignment: .trailing, spacing: cellSpacing) {
                        ForEach(days, id: \.self) { day in
                            Text(String(day.prefix(1)))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }

                    // Hour columns (0-23)
                    ForEach(0..<24, id: \.self) { hour in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorFor(day: dayIndex, hour: hour))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }

            // Hour labels
            HStack(spacing: 0) {
                Text("")
                    .frame(width: cellSize + cellSpacing)

                ForEach([0, 6, 12, 18, 23], id: \.self) { hour in
                    Text("\(hour)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private func colorFor(day: Int, hour: Int) -> Color {
        guard let stressLevel = stressLevelFor(day: day, hour: hour) else {
            return Color.secondary.opacity(0.1)
        }

        switch stressLevel {
        case 0...25: return .stressRelaxed
        case 26...50: return .stressMild
        case 51...75: return .stressModerate
        default: return .stressHigh
        }
    }

    private func stressLevelFor(day: Int, hour: Int) -> Double? {
        let calendar = Calendar.current
        let now = Date()

        guard let dayStart = calendar.date(byAdding: .day, value: -(6 - day), to: calendar.startOfDay(for: now)),
              let hourStart = calendar.date(byAdding: .hour, value: hour, to: dayStart),
              let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else {
            return nil
        }

        let hourMeasurements = measurements.filter { m in
            m.timestamp >= hourStart && m.timestamp < hourEnd
        }

        guard !hourMeasurements.isEmpty else { return nil }

        return hourMeasurements.map { $0.stressLevel }.reduce(0, +) / Double(hourMeasurements.count)
    }
}

#Preview {
    WeeklyHeatmapView(measurements: [])
        .padding()
}
