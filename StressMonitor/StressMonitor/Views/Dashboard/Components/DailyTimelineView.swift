import SwiftUI

/// Timeline view showing intraday stress patterns
/// Displays 24-hour timeline with markers at 6-hour intervals
struct DailyTimelineView: View {
    let measurements: [StressMeasurement]
    let isExpanded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let hourMarkers: [Int] = [0, 6, 12, 18, 24]
    private let collapsedHeight: CGFloat = 60
    private let expandedHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Timeline")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if !measurements.isEmpty {
                        Text(averageText)
                            .font(.caption)
                            .foregroundColor(.oledTextSecondary)
                    }
                }

                Spacer()

                if measurements.isEmpty {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.oledTextSecondary)
                } else {
                    Text("\(measurements.count) measurements")
                        .font(.caption)
                        .foregroundColor(.oledTextSecondary)
                }
            }

            // Timeline
            if measurements.isEmpty {
                emptyTimeline
            } else {
                timelineContent
            }
        }
        .padding(16)
        .background(Color.oledCardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Empty State

    private var emptyTimeline: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(hourMarkers.dropLast(), id: \.self) { hour in
                    Text(formatHour(hour))
                        .font(.caption2)
                        .foregroundColor(.oledTextSecondary)
                    Spacer()
                }
                Text("24")
                    .font(.caption2)
                    .foregroundColor(.oledTextSecondary)
            }

            Rectangle()
                .fill(Color.oledCardSecondary)
                .frame(height: 40)
                .cornerRadius(8)
                .overlay(
                    Text("Measure throughout the day to see patterns")
                        .font(.caption)
                        .foregroundColor(.oledTextSecondary)
                )
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        GeometryReader { geometry in
            let chartHeight = isExpanded ? expandedHeight : collapsedHeight

            ZStack(alignment: .top) {
                // Hour markers and grid lines
                HStack(spacing: 0) {
                    ForEach(Array(hourMarkers.enumerated()), id: \.element) { index, hour in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatHour(hour))
                                .font(.system(size: 9))
                                .foregroundColor(.oledTextSecondary)

                            Rectangle()
                                .fill(Color.oledCardSecondary)
                                .frame(width: 1, height: chartHeight - 16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if index < hourMarkers.count - 1 {
                            Spacer()
                        }
                    }
                }

                // Data points
                ForEach(groupedByHour(), id: \.hour) { group in
                    dataPoint(for: group, in: geometry.size)
                }

                // Current time indicator
                currentTimeIndicator(in: geometry.size, chartHeight: chartHeight)
            }
        }
        .frame(height: isExpanded ? expandedHeight + 24 : collapsedHeight + 24)
        .clipped()
    }

    // MARK: - Data Point View

    private func dataPoint(for group: HourlyDataGroup, in size: CGSize) -> some View {
        let chartHeight = isExpanded ? expandedHeight : collapsedHeight
        let xPosition = (size.width / 24) * CGFloat(group.hour)
        let yPosition = chartHeight - (chartHeight * (group.averageStress / 100))

        return Circle()
            .fill(Color.stressColor(for: group.averageStress))
            .frame(width: pointSize(for: group.count), height: pointSize(for: group.count))
            .overlay(
                Text("\(group.count)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(group.count > 1 ? 1 : 0)
            )
            .position(x: xPosition, y: yPosition)
            .accessibilityHidden(true)
    }

    private func pointSize(for count: Int) -> CGFloat {
        min(10 + CGFloat(count * 3), 24)
    }

    // MARK: - Current Time Indicator

    private func currentTimeIndicator(in size: CGSize, chartHeight: CGFloat) -> some View {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMinute = Calendar.current.component(.minute, from: Date())
        let hourFraction = Double(currentHour) + Double(currentMinute) / 60.0
        let xPosition = (size.width / 24) * hourFraction

        return VStack(spacing: 0) {
            Triangle()
                .fill(Color.primaryBlue)
                .frame(width: 10, height: 5)

            Rectangle()
                .fill(Color.primaryBlue)
                .frame(width: 2, height: chartHeight - 16)
        }
        .position(x: xPosition, y: chartHeight / 2)
        .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 6: return "6 AM"
        case 12: return "12 PM"
        case 18: return "6 PM"
        case 24: return "12 AM"
        default: return "\(hour)"
        }
    }

    private func groupedByHour() -> [HourlyDataGroup] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: measurements) { measurement -> Int in
            calendar.component(.hour, from: measurement.timestamp)
        }

        return groups.map { hour, measurements in
            HourlyDataGroup(
                hour: hour,
                averageStress: measurements.map(\.stressLevel).reduce(0, +) / Double(measurements.count),
                count: measurements.count
            )
        }.sorted { $0.hour < $1.hour }
    }

    private var averageText: String {
        guard !measurements.isEmpty else { return "" }
        let avg = measurements.map(\.stressLevel).reduce(0, +) / Double(measurements.count)
        return "Avg: \(Int(avg))%"
    }

    private var accessibilityDescription: String {
        if measurements.isEmpty {
            return "Today's timeline: No measurements yet"
        }

        let avg = measurements.map(\.stressLevel).reduce(0, +) / Double(measurements.count)
        return "Today's timeline: \(measurements.count) measurements, average stress \(Int(avg)) percent"
    }
}

// MARK: - Supporting Types

struct HourlyDataGroup {
    let hour: Int
    let averageStress: Double
    let count: Int
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Timeline - Empty") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()
        DailyTimelineView(measurements: [], isExpanded: false)
            .padding()
    }
}

#Preview("Timeline - With Data") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        let measurements = (0..<10).map { i in
            StressMeasurement(
                timestamp: Calendar.current.date(byAdding: .hour, value: i * 2, to: Date()) ?? Date(),
                stressLevel: Double.random(in: 20...70),
                hrv: Double.random(in: 30...80),
                restingHeartRate: 60,
                confidences: [0.8]
            )
        }

        DailyTimelineView(measurements: measurements, isExpanded: false)
            .padding()
    }
}
