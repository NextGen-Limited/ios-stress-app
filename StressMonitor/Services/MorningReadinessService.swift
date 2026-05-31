import Foundation
import HealthKit

/// Morning Readiness assessment based on HRV trend analysis.
/// Compares today's morning HRV against a 7-day rolling baseline to produce
/// a readiness score (0–100) with actionable insights.
///
/// Inspired by WHOOP Recovery, Oura Readiness, and Garmin Body Battery.
@MainActor
class MorningReadinessService: ObservableObject {

    // MARK: - Published State

    @Published var readinessScore: Double?       // 0–100, nil if no morning data
    @Published var readinessLevel: ReadinessLevel = .noData
    @Published var morningHRV: Double?           // Today's morning HRV (SDNN ms)
    @Published var baselineHRV: Double           // 7-day rolling average
    @Published var hrvTrend: [DailyHRVPoint] = [] // Last 7 days for sparkline
    @Published var insights: [ReadinessInsight] = []
    @Published var lastComputed: Date?

    // MARK: - Types

    enum ReadinessLevel: String, CaseIterable {
        case noData     = "No Data"
        case low        = "Low"
        case moderate   = "Moderate"
        case good       = "Good"
        case excellent  = "Excellent"

        var color: String {
            switch self {
            case .noData:   return "gray"
            case .low:      return "red"
            case .moderate: return "orange"
            case .good:     return "green"
            case .excellent:return "mint"
            }
        }

        var emoji: String {
            switch self {
            case .noData:   return "—"
            case .low:      return "🔴"
            case .moderate: return "🟠"
            case .good:     return "🟢"
            case .excellent:return "💚"
            }
        }

        var advice: String {
            switch self {
            case .noData:
                return "Wear your Apple Watch overnight to get a morning readiness score."
            case .low:
                return "Your body needs rest today. Prioritize recovery — light activity, hydration, and sleep."
            case .moderate:
                return "You're recovering. Consider moderate activity and stress management today."
            case .good:
                return "You're well-recovered. Good day for normal to high-intensity activities."
            case .excellent:
                return "Peak readiness! Your body is primed for high performance today."
            }
        }
    }

    struct DailyHRVPoint: Identifiable {
        let id = UUID()
        let date: Date
        let hrv: Double
        let isToday: Bool
    }

    struct ReadinessInsight: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    // MARK: - Configuration

    /// Morning window: 4 AM – 10 AM (user's local time)
    static let morningStartHour = 4
    static let morningEndHour = 10

    /// Baseline window: last 7 days
    static let baselineDays = 7

    // MARK: - Dependencies

    private let healthStore = HKHealthStore()

    // MARK: - Public API

    /// Compute morning readiness from HealthKit data.
    /// Call on app launch or pull-to-refresh.
    func computeReadiness() async {
        do {
            // 1. Fetch today's morning HRV samples
            let todayMorningHRV = try await fetchMorningHRV(for: Date())

            // 2. Fetch 7-day historical morning HRV averages
            let dailyAverages = try await fetchDailyMorningHRVAverages(days: Self.baselineDays)

            await MainActor.run {
                // 3. Compute baseline from historical daily averages
                let historicalValues = dailyAverages.map { $0.hrv }
                baselineHRV = historicalValues.isEmpty ? 60.0 : historicalValues.reduce(0, +) / Double(historicalValues.count)

                // 4. Build trend data (last 7 days + today)
                var trend = dailyAverages.map { DailyHRVPoint(date: $0.date, hrv: $0.hrv, isToday: false) }

                // 5. Compute today's morning average
                if !todayMorningHRV.isEmpty {
                    let todayAvg = todayMorningHRV.reduce(0, +) / Double(todayMorningHRV.count)
                    morningHRV = todayAvg
                    trend.append(DailyHRVPoint(date: Date(), hrv: todayAvg, isToday: true))

                    // 6. Compute readiness score
                    readinessScore = Self.computeScore(morningHRV: todayAvg, baseline: baselineHRV)
                    readinessLevel = Self.categorize(score: readinessScore!)

                    // 7. Generate insights
                    insights = Self.generateInsights(
                        morningHRV: todayAvg,
                        baseline: baselineHRV,
                        recentTrend: historicalValues,
                        sampleCount: todayMorningHRV.count
                    )
                } else {
                    morningHRV = nil
                    readinessScore = nil
                    readinessLevel = .noData
                    insights = [ReadinessInsight(
                        icon: "bed.double",
                        title: "No Morning Data",
                        detail: "Wear your Apple Watch during sleep for automatic morning readiness checks."
                    )]
                }

                hrvTrend = trend
                lastComputed = Date()
            }
        } catch {
            await MainActor.run {
                readinessLevel = .noData
                insights = [ReadinessInsight(
                    icon: "exclamationmark.triangle",
                    title: "Data Unavailable",
                    detail: "Could not fetch HRV data. Check HealthKit permissions."
                )]
            }
        }
    }

    // MARK: - Score Computation

    /// Compute readiness score (0–100) from morning HRV vs baseline.
    /// Uses a sigmoid-like curve so that:
    ///   - morningHRV == baseline → ~50 (moderate)
    ///   - morningHRV > baseline → approaches 100
    ///   - morningHRV < baseline → approaches 0
    static func computeScore(morningHRV: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 50 }

        let ratio = morningHRV / baseline

        // Sigmoid mapping: ratio 1.0 → 50, ratio 1.3 → ~80, ratio 0.7 → ~20
        let x = (ratio - 1.0) * 5.0  // Scale: ±0.3 ratio → ±1.5
        let sigmoid = 1.0 / (1.0 + exp(-x))
        let score = sigmoid * 100.0

        return max(0, min(100, score))
    }

    static func categorize(score: Double) -> ReadinessLevel {
        switch score {
        case 0..<25:    return .low
        case 25..<50:   return .moderate
        case 50..<75:   return .good
        default:         return .excellent
        }
    }

    // MARK: - Insight Generation

    private static func generateInsights(
        morningHRV: Double,
        baseline: Double,
        recentTrend: [Double],
        sampleCount: Int
    ) -> [ReadinessInsight] {
        var result: [ReadinessInsight] = []

        // HRV vs baseline insight
        let deviation = ((morningHRV - baseline) / baseline) * 100
        if deviation > 10 {
            result.append(ReadinessInsight(
                icon: "arrow.up.circle.fill",
                title: "Above Baseline",
                detail: String(format: "Your morning HRV is %.0f%% above your 7-day average (%.0f vs %.0f ms).",
                              deviation, morningHRV, baseline)
            ))
        } else if deviation < -10 {
            result.append(ReadinessInsight(
                icon: "arrow.down.circle.fill",
                title: "Below Baseline",
                detail: String(format: "Your morning HRV is %.0f%% below your 7-day average (%.0f vs %.0f ms). Your body may need more recovery.",
                              abs(deviation), morningHRV, baseline)
            ))
        } else {
            result.append(ReadinessInsight(
                icon: "equal.circle.fill",
                title: "On Track",
                detail: String(format: "Your morning HRV is in line with your 7-day average (%.0f vs %.0f ms).",
                              morningHRV, baseline)
            ))
        }

        // Trend insight (last 3 days direction)
        if recentTrend.count >= 3 {
            let recent3 = Array(recentTrend.suffix(3))
            let trendSlope = computeTrendSlope(recent3)
            if trendSlope > 2 {
                result.append(ReadinessInsight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Upward Trend",
                    detail: "Your morning HRV has been trending up over the last few days — recovery is improving."
                ))
            } else if trendSlope < -2 {
                result.append(ReadinessInsight(
                    icon: "chart.line.downtrend.xyaxis",
                    title: "Downward Trend",
                    detail: "Your morning HRV has been declining. Consider reducing training load or improving sleep."
                ))
            }
        }

        // Sample quality insight
        if sampleCount < 3 {
            result.append(ReadinessInsight(
                icon: "waveform.path.ecg",
                title: "Limited Data",
                detail: "Only \(sampleCount) HRV reading(s) this morning. More readings improve accuracy."
            ))
        }

        return result
    }

    /// Simple linear regression slope for trend detection.
    private static func computeTrendSlope(_ values: [Double]) -> Double {
        let n = Double(values.count)
        let xMean = (n - 1) / 2.0
        let yMean = values.reduce(0, +) / n

        var numerator: Double = 0
        var denominator: Double = 0
        for (i, v) in values.enumerated() {
            let x = Double(i) - xMean
            numerator += x * (v - yMean)
            denominator += x * x
        }

        return denominator > 0 ? numerator / denominator : 0
    }

    // MARK: - HealthKit Queries

    /// Fetch morning HRV samples for a specific day.
    private func fetchMorningHRV(for date: Date) async throws -> [Double] {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = Self.morningStartHour
        var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endComponents.hour = Self.morningEndHour

        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(from: endComponents) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await fetchHRVValues(predicate: predicate)
    }

    /// Fetch daily morning HRV averages for the last N days (excluding today).
    private func fetchDailyMorningHRVAverages(days: Int) async throws -> [(date: Date, hrv: Double)] {
        let calendar = Calendar.current
        var results: [(Date, Double)] = []

        for dayOffset in 1...days {  // Skip today (offset 0)
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

            let samples = try await fetchMorningHRV(for: date)
            if !samples.isEmpty {
                let avg = samples.reduce(0, +) / Double(samples.count)
                results.append((date, avg))
            }
        }

        return results.reversed() // Oldest first for chart display
    }

    /// Fetch HRV values matching a predicate.
    private func fetchHRVValues(predicate: NSPredicate) async throws -> [Double] {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let values = (samples as? [HKQuantitySample])?.map {
                        $0.quantity.doubleValue(for: .secondUnit(with: .milli))
                    } ?? []
                    continuation.resume(returning: values)
                }
            }
            healthStore.execute(query)
        }
    }
}
