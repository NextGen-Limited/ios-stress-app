import Foundation

struct FactorBreakdown: Codable, Sendable {
    let hrvComponent: Double?
    let hrComponent: Double?
    let sleepComponent: Double?
    let activityComponent: Double?
    let recoveryComponent: Double?
    let dataCompleteness: Double
}
