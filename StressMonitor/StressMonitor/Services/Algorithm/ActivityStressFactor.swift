import Foundation

// MARK: - ActivityStressFactor

/// Activity-based stress factor (weight: 0.15).
/// Sedentary patterns increase stress contribution; post-workout state suppressed for 2h.
/// Returns nil if activity data is unavailable.
struct ActivityStressFactor: StressFactor {
    let id = "activity"
    let weight = 0.15

    func calculate(context: StressContext) async throws -> FactorResult? {
        guard let activity = context.activityData else { return nil }

        let stepStress = stressFromSteps(activity.stepCount)
        let energyStress = stressFromEnergy(activity.activeEnergyKcal)
        let standStress = stressFromStanding(activity.standHours)

        var combined = stepStress * 0.40 + energyStress * 0.35 + standStress * 0.25

        // Post-workout grace period: suppress contribution for 2h after workout
        if let workoutEnd = activity.lastWorkoutEndTime {
            let hoursSince = Date().timeIntervalSince(workoutEnd) / 3600.0
            if hoursSince < 2.0 {
                combined *= max(0.3, hoursSince / 2.0)
            }
        }

        return FactorResult(
            value: max(0, min(1.0, combined)),
            confidence: 0.85,
            metadata: [
                "steps": Double(activity.stepCount),
                "activeEnergy": activity.activeEnergyKcal,
                "standHours": Double(activity.standHours)
            ]
        )
    }

    // 10,000+ steps = no stress; <2,000 = high stress
    private func stressFromSteps(_ steps: Int) -> Double {
        max(0, 1.0 - min(1.0, Double(steps) / 10000.0))
    }

    // 300+ kcal = no stress; <50 kcal = high stress
    private func stressFromEnergy(_ kcal: Double) -> Double {
        max(0, 1.0 - min(1.0, kcal / 300.0))
    }

    // 10+ stand hours = no stress; <4 = high stress
    private func stressFromStanding(_ hours: Int) -> Double {
        max(0, 1.0 - min(1.0, Double(hours) / 10.0))
    }
}
