import Foundation

// MARK: - SleepStressFactor

/// Sleep quality stress factor (weight: 0.20).
/// Short duration, poor quality (low deep+REM), and low efficiency increase stress.
/// Returns nil if sleep data is unavailable (no watch worn overnight, permission denied).
struct SleepStressFactor: StressFactor {
    let id = "sleep"
    let weight = 0.20

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let sleep = context.sleepData else { return nil }

        // Duration: <4h = max stress, 8h+ = no stress
        let durationStress = max(0, min(1.0, (8.0 - sleep.totalSleepHours) / 4.0))

        // Quality: deep+REM proportion; less restorative sleep = higher stress
        let restorativeProportion = sleep.totalSleepHours > 0
            ? (sleep.deepSleepHours + sleep.remSleepHours) / sleep.totalSleepHours
            : 0
        let qualityStress = max(0, 1.0 - restorativeProportion)

        // Efficiency: fragmented sleep = more stress
        let efficiencyStress = max(0, 1.0 - sleep.sleepEfficiency)

        let combined = durationStress * 0.40 + qualityStress * 0.35 + efficiencyStress * 0.25

        return FactorResult(
            value: max(0, min(1.0, combined)),
            confidence: 0.85,
            metadata: [
                "totalSleepHours": sleep.totalSleepHours,
                "deepSleepHours": sleep.deepSleepHours,
                "remSleepHours": sleep.remSleepHours,
                "sleepEfficiency": sleep.sleepEfficiency
            ]
        )
    }
}
