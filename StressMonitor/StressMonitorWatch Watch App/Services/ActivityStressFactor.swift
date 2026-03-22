import Foundation

struct ActivityStressFactor: StressFactor {
    let id = "activity"
    let weight = 0.15

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let activity = context.activityData else { return nil }

        let stepStress = max(0, 1.0 - min(1.0, Double(activity.stepCount) / 10000.0))
        let energyStress = max(0, 1.0 - min(1.0, activity.activeEnergyKcal / 300.0))
        let standStress = max(0, 1.0 - min(1.0, Double(activity.standHours) / 10.0))

        var combined = stepStress * 0.40 + energyStress * 0.35 + standStress * 0.25

        if let workoutEnd = activity.lastWorkoutEndTime {
            let hoursSince = Date().timeIntervalSince(workoutEnd) / 3600.0
            if hoursSince < 2.0 { combined *= max(0.3, hoursSince / 2.0) }
        }

        return FactorResult(value: max(0, min(1.0, combined)), confidence: 0.85,
                            metadata: ["steps": Double(activity.stepCount)])
    }
}
