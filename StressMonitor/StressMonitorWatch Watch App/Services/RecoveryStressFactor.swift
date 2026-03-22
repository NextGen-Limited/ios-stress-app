import Foundation

struct RecoveryStressFactor: StressFactor {
    let id = "recovery"
    let weight = 0.10

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let recovery = context.recoveryData else { return nil }

        var components: [(value: Double, weight: Double)] = []
        if let rr = recovery.respiratoryRate {
            components.append((max(0, min(1.0, (rr - 12.0) / 16.0)), 0.40))
        }
        if let spo2 = recovery.bloodOxygen {
            components.append((max(0, min(1.0, (100.0 - spo2) / 8.0)), 0.30))
        }
        if let trend = recovery.restingHRTrend {
            components.append((max(0, min(1.0, trend / 10.0)), 0.30))
        }

        guard !components.isEmpty else { return nil }
        let totalWeight = components.reduce(0) { $0 + $1.weight }
        let combined = components.reduce(0.0) { $0 + $1.value * ($1.weight / totalWeight) }

        return FactorResult(value: combined,
                            confidence: 0.6 + Double(components.count) / 3.0 * 0.3,
                            metadata: [:])
    }
}
