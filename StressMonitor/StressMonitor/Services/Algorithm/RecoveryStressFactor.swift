import Foundation

// MARK: - RecoveryStressFactor

/// Physiological recovery stress factor (weight: 0.10).
/// Elevated respiratory rate, low SpO2, or rising resting HR indicate poor recovery.
/// Returns nil only if all sub-metrics are nil (e.g. no Apple Watch, no sleep tracking).
struct RecoveryStressFactor: StressFactor {
    let id = "recovery"
    let weight = 0.10

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let recovery = context.recoveryData else { return nil }

        var components: [(value: Double, weight: Double)] = []

        // Respiratory rate: normal 12-20 bpm; >28 = max stress
        if let rr = recovery.respiratoryRate {
            let stress = max(0, min(1.0, (rr - 12.0) / 16.0))
            components.append((stress, 0.40))
        }

        // SpO2: normal >96%; <92% = significant stress
        if let spo2 = recovery.bloodOxygen {
            let stress = max(0, min(1.0, (100.0 - spo2) / 8.0))
            components.append((stress, 0.30))
        }

        // Resting HR trend: +10bpm over 7-day avg = max stress
        if let trend = recovery.restingHRTrend {
            let stress = max(0, min(1.0, trend / 10.0))
            components.append((stress, 0.30))
        }

        guard !components.isEmpty else { return nil }

        let totalSubWeight = components.reduce(0) { $0 + $1.weight }
        let combined = components.reduce(0.0) { $0 + $1.value * ($1.weight / totalSubWeight) }

        // Confidence scales with data availability (1 sub-metric → 0.7, 3 → 0.9)
        let dataAvailability = Double(components.count) / 3.0
        let confidence = 0.6 + dataAvailability * 0.3

        return FactorResult(
            value: combined,
            confidence: confidence,
            metadata: [
                "respiratoryRate": recovery.respiratoryRate ?? -1,
                "bloodOxygen": recovery.bloodOxygen ?? -1,
                "restingHRTrend": recovery.restingHRTrend ?? 0
            ]
        )
    }
}
