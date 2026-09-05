import Foundation

/// GET /stress/scores row + POST /health/daily-summary response body.
struct ServerStressScore: Codable, Equatable, Sendable {
    let localDate: String
    let score: Int
    let level: String
    let confidence: Double
    let formulaVersion: String
    let baselineVersion: String
    let factors: [String]
    let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case localDate = "local_date"
        case score
        case level
        case confidence
        case formulaVersion = "formula_version"
        case baselineVersion = "baseline_version"
        case factors
        case warnings
    }
}
