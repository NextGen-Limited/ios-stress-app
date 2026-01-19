import SwiftUI
import SwiftData

@Observable
class TrendsViewModel {
    var selectedTimeRange: TrendsTimeRange = .week
    var hrvData: [ChartDataPoint] = []
    var averageHRV: Double = 0
    var hrvRange: ClosedRange<Double> = 0...0
    var trendDirection: TrendDirection = .stable
    var stressDistribution: StressDistribution = .init()
    var weeklyInsight: String?
    var patternInsights: [PatternInsight] = []
    var selectedDataPoint: ChartDataPoint?
    var isLoading = false

    private let repository: StressRepositoryProtocol

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
    }

    func loadTrendData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let calendar = Calendar.current
            let now = Date()
            var startDate: Date
            var groupBy: Calendar.Component

            switch selectedTimeRange {
            case .day:
                startDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
                groupBy = .hour
            case .week:
                startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                groupBy = .day
            case .month:
                startDate = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
                groupBy = .day
            case .threeMonths:
                startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                groupBy = .weekOfYear
            }

            let measurements = try await repository.fetchMeasurements(from: startDate, to: now)

            hrvData = processChartData(measurements: measurements, groupBy: groupBy)
            averageHRV = calculateAverage(from: hrvData)
            hrvRange = calculateRange(from: hrvData)
            trendDirection = calculateTrend()
            stressDistribution = calculateDistribution(measurements: measurements)
            weeklyInsight = generateWeeklyInsight(measurements: measurements)
            patternInsights = generatePatternInsights(measurements: measurements)

        } catch {
            hrvData = []
        }
    }

    private func processChartData(measurements: [StressMeasurement], groupBy: Calendar.Component) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: measurements) { measurement in
            calendar.dateComponents([groupBy], from: measurement.timestamp)
        }

        return grouped.map { components, measurements in
            let avgHRV = measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
            let date = components.date ?? Date()
            return ChartDataPoint(date: date, value: avgHRV)
        }.sorted { $0.date < $1.date }
    }

    private func calculateAverage(from data: [ChartDataPoint]) -> Double {
        guard !data.isEmpty else { return 0 }
        return data.map { $0.value }.reduce(0, +) / Double(data.count)
    }

    private func calculateRange(from data: [ChartDataPoint]) -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...0 }
        let values = data.map { $0.value }
        return (values.min() ?? 0)...(values.max() ?? 0)
    }

    private func calculateTrend() -> TrendDirection {
        guard hrvData.count >= 2 else { return .stable }

        let recent = hrvData.suffix(3).map { $0.value }.reduce(0, +) / Double(min(3, hrvData.count))
        let older = hrvData.prefix(3).map { $0.value }.reduce(0, +) / Double(min(3, hrvData.count))

        let diff = recent - older
        if diff > 5 { return .up }
        if diff < -5 { return .down }
        return .stable
    }

    private func calculateDistribution(measurements: [StressMeasurement]) -> StressDistribution {
        guard !measurements.isEmpty else { return .init() }

        let total = Double(measurements.count)

        return StressDistribution(
            relaxed: Double(measurements.filter { $0.stressLevel <= 25 }.count) / total * 100,
            normal: Double(measurements.filter { $0.stressLevel > 25 && $0.stressLevel <= 50 }.count) / total * 100,
            elevated: Double(measurements.filter { $0.stressLevel > 50 && $0.stressLevel <= 75 }.count) / total * 100,
            high: Double(measurements.filter { $0.stressLevel > 75 }.count) / total * 100
        )
    }

    private func generateWeeklyInsight(measurements: [StressMeasurement]) -> String {
        guard measurements.count >= 7 else {
            return "Continue tracking for 7 days to unlock weekly insights"
        }

        let calendar = Calendar.current
        let now = Date()
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart

        let thisWeek = measurements.filter { $0.timestamp >= thisWeekStart }
        let lastWeek = measurements.filter { $0.timestamp >= lastWeekStart && $0.timestamp < thisWeekStart }

        guard !thisWeek.isEmpty, !lastWeek.isEmpty else {
            return "Track for another week to see week-over-week changes"
        }

        let thisWeekAvg = thisWeek.map { $0.hrv }.reduce(0, +) / Double(thisWeek.count)
        let lastWeekAvg = lastWeek.map { $0.hrv }.reduce(0, +) / Double(lastWeek.count)
        let change = ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100

        if change > 10 {
            return "Your HRV is \(Int(change))% higher this week - great recovery!"
        } else if change < -10 {
            return "Your HRV is \(Int(abs(change)))% lower this week - prioritize rest"
        } else {
            return "Your HRV is stable compared to last week"
        }
    }

    private func generatePatternInsights(measurements: [StressMeasurement]) -> [PatternInsight] {
        var insights: [PatternInsight] = []

        let calendar = Calendar.current
        let weekdayAvg = Dictionary(grouping: measurements) { calendar.component(.weekday, from: $0.timestamp) }
            .mapValues { measurements in
                measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
            }

        let weekdayAvgValues = Array(weekdayAvg.values)
        if weekdayAvgValues.count >= 5 {
            let saturdayAvg = weekdayAvg[7] ?? 0
            let sundayAvg = weekdayAvg[1] ?? 0
            let weekendAvg = (saturdayAvg + sundayAvg) / 2
            let weekdayAvgCalc = weekdayAvgValues.filter { $0 != saturdayAvg && $0 != sundayAvg }.reduce(0, +) / Double(weekdayAvgValues.count - 2)

            if weekendAvg > weekdayAvgCalc * 1.1 {
                insights.append(PatternInsight(
                    icon: "📈",
                    title: "Weekly Pattern",
                    description: "Your HRV is \(Int(((weekendAvg / weekdayAvgCalc) - 1) * 100))% higher on weekends vs weekdays"
                ))
            }
        }

        if let bestDay = weekdayAvg.max(by: { $0.value < $1.value }) {
            let dayName = calendar.weekdaySymbols[bestDay.key - 1]
            insights.append(PatternInsight(
                icon: "💤",
                title: "Best Recovery Day",
                description: "\(dayName) (\(Int(bestDay.value)) ms average)"
            ))
        }

        if let bestHRV = measurements.map({ $0.hrv }).max(), let bestDate = measurements.first(where: { $0.hrv == bestHRV })?.timestamp {
            insights.append(PatternInsight(
                icon: "🏃",
                title: "Personal Best",
                description: "\(Int(bestHRV)) ms on \(formatDate(bestDate))"
            ))
        }

        return insights
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
    }
}

struct StressDistribution {
    var relaxed: Double = 0
    var normal: Double = 0
    var elevated: Double = 0
    var high: Double = 0
}

struct PatternInsight {
    let icon: String
    let title: String
    let description: String
}

enum TrendsTimeRange: String {
    case day = "24H"
    case week = "7D"
    case month = "4W"
    case threeMonths = "3M"
}
