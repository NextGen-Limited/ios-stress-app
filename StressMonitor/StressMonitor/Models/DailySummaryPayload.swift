import Foundation

/// POST /health/daily-summary body — the one place health measurements
/// leave the device. Field names are the backend contract (snake_case).
struct DailySummaryPayload: Codable, Equatable, Sendable {
    let localDate: String
    let timezone: String
    let hrvSdnnMs: Double?
    let heartRateAvgBpm: Double?
    let restingHeartRateBpm: Double?
    let sampleCounts: SampleCounts
    let source: String

    struct SampleCounts: Codable, Equatable, Sendable {
        let hrv: Int
        let heartRate: Int
        let restingHeartRate: Int

        enum CodingKeys: String, CodingKey {
            case hrv
            case heartRate = "heart_rate"
            case restingHeartRate = "resting_heart_rate"
        }
    }

    enum CodingKeys: String, CodingKey {
        case localDate = "local_date"
        case timezone
        case hrvSdnnMs = "hrv_sdnn_ms"
        case heartRateAvgBpm = "heart_rate_avg_bpm"
        case restingHeartRateBpm = "resting_heart_rate_bpm"
        case sampleCounts = "sample_counts"
        case source
    }

    init(
        localDate: String,
        timezone: String,
        hrvSdnnMs: Double?,
        heartRateAvgBpm: Double?,
        restingHeartRateBpm: Double?,
        sampleCounts: SampleCounts,
        source: String
    ) {
        self.localDate = localDate
        self.timezone = timezone
        self.hrvSdnnMs = hrvSdnnMs
        self.heartRateAvgBpm = heartRateAvgBpm
        self.restingHeartRateBpm = restingHeartRateBpm
        self.sampleCounts = sampleCounts
        self.source = source
    }
}
