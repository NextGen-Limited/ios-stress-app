import Foundation

// MARK: - Stress Context Payload

/// Structured health context sent to the Supabase Edge Function `/chat`.
/// The backend builds the system prompt from this data — the iOS app no longer
/// builds the prompt locally.
struct StressContextPayload: Codable, Sendable {
    let stressLevel: Int?
    let stressCategory: String?
    let confidence: Double?
    let hrv: Double?
    let heartRate: Double?
    let baselineHRV: Double?
    let baselineHR: Double?
    let sleepQuality: Int?
    let sleepHours: Double?
    let activeMinutes: Int?
    let recoveryScore: Int?
    let stressTrend: String?
    let stressTrendDelta: String?
    let hrvTrend: String?
    let sleepTrend: String?
    let factorBreakdown: FactorBreakdownPayload?
    let language: String
    let coachingStyle: String

    // MARK: - Nested Types

    struct FactorBreakdownPayload: Codable, Sendable {
        let hrvComponent: Double?
        let hrComponent: Double?
        let sleepComponent: Double?
        let activityComponent: Double?
        let recoveryComponent: Double?
        let dataCompleteness: Double?
    }

    // MARK: - Coding Keys (snake_case for JSON)

    enum CodingKeys: String, CodingKey {
        case stressLevel = "stress_level"
        case stressCategory = "stress_category"
        case confidence
        case hrv
        case heartRate = "heart_rate"
        case baselineHRV = "baseline_hrv"
        case baselineHR = "baseline_hr"
        case sleepQuality = "sleep_quality"
        case sleepHours = "sleep_hours"
        case activeMinutes = "active_minutes"
        case recoveryScore = "recovery_score"
        case stressTrend = "stress_trend"
        case stressTrendDelta = "stress_trend_delta"
        case hrvTrend = "hrv_trend"
        case sleepTrend = "sleep_trend"
        case factorBreakdown = "factor_breakdown"
        case language
        case coachingStyle = "coaching_style"
    }

    // MARK: - Builder

    /// Build a stress context payload from the current health data available in ChatViewModel.
    static func build(
        stressResult: StressResult?,
        baseline: PersonalBaseline?,
        recentHistory: [StressMeasurement] = [],
        language: String = "en",
        coachingStyle: String = "empathetic"
    ) -> StressContextPayload {
        // Trend analysis
        var trend: String? = nil
        var trendDelta: String? = nil
        let recent = recentHistory.suffix(min(5, max(2, recentHistory.count)))
        if recent.count >= 2 {
            let levels = recent.map(\.stressLevel)
            let first = levels.first!
            let last = levels.last!
            let diff = last - first
            if abs(diff) < 5 {
                trend = "stable"
            } else if diff > 0 {
                trend = "rising"
            } else {
                trend = "declining"
            }
            trendDelta = String(format: "%+.0f%%", diff)
        }

        // Factor breakdown
        var factorPayload: FactorBreakdownPayload? = nil
        if let fb = stressResult?.factorBreakdown {
            factorPayload = FactorBreakdownPayload(
                hrvComponent: fb.hrvComponent,
                hrComponent: fb.hrComponent,
                sleepComponent: fb.sleepComponent,
                activityComponent: fb.activityComponent,
                recoveryComponent: fb.recoveryComponent,
                dataCompleteness: fb.dataCompleteness
            )
        }

        return StressContextPayload(
            stressLevel: stressResult.map { Int($0.level) },
            stressCategory: stressResult?.category.rawValue,
            confidence: stressResult?.confidence,
            hrv: stressResult?.hrv,
            heartRate: stressResult?.heartRate,
            baselineHRV: baseline?.baselineHRV,
            baselineHR: baseline?.restingHeartRate,
            sleepQuality: nil,  // Not directly available from StressResult
            sleepHours: nil,
            activeMinutes: nil,
            recoveryScore: nil,
            stressTrend: trend,
            stressTrendDelta: trendDelta,
            hrvTrend: nil,
            sleepTrend: nil,
            factorBreakdown: factorPayload,
            language: language,
            coachingStyle: coachingStyle
        )
    }
}
