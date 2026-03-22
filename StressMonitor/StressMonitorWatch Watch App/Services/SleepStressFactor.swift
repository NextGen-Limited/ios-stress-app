import Foundation

struct SleepStressFactor: StressFactor {
    let id = "sleep"
    let weight = 0.20

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let sleep = context.sleepData else { return nil }

        let durationStress = max(0, min(1.0, (8.0 - sleep.totalSleepHours) / 4.0))
        let restorativeProportion = sleep.totalSleepHours > 0
            ? (sleep.deepSleepHours + sleep.remSleepHours) / sleep.totalSleepHours : 0
        let qualityStress = max(0, 1.0 - restorativeProportion)
        let efficiencyStress = max(0, 1.0 - sleep.sleepEfficiency)

        let combined = durationStress * 0.40 + qualityStress * 0.35 + efficiencyStress * 0.25
        return FactorResult(value: max(0, min(1.0, combined)), confidence: 0.85,
                            metadata: ["totalSleepHours": sleep.totalSleepHours])
    }
}
