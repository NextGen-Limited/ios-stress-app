import XCTest
@testable import StressMonitor

final class ActivityStressFactorTests: XCTestCase {

    private let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
    private let factor = ActivityStressFactor()

    private func makeContext(activity: ActivityData?) -> StressContext {
        StressContext(baseline: baseline, hrv: 50, heartRate: 60, activityData: activity)
    }

    private func makeActivity(steps: Int = 8000, energy: Double = 250,
                               standHours: Int = 8, workoutEnd: Date? = nil,
                               workoutDuration: Double? = nil) -> ActivityData {
        ActivityData(stepCount: steps, activeEnergyKcal: energy, standHours: standHours,
                     lastWorkoutEndTime: workoutEnd, lastWorkoutDurationMinutes: workoutDuration,
                     analysisDate: Date())
    }

    func testNilActivity_returnsNil() async throws {
        let result = try await factor.calculate(context: makeContext(activity: nil))
        XCTAssertNil(result, "Missing activity data should return nil")
    }

    func testActiveDay_lowStress() async throws {
        // 10000 steps, 300 kcal, 10 stand hours → all sub-scores = 0
        let activity = makeActivity(steps: 10000, energy: 300, standHours: 10)
        let result = try await factor.calculate(context: makeContext(activity: activity))
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.value, 0.0, accuracy: 0.05, "Fully active day → near-zero stress")
    }

    func testSedentaryDay_highStress() async throws {
        // 500 steps, 20 kcal, 2 stand hours → all sub-scores near 1
        let activity = makeActivity(steps: 500, energy: 20, standHours: 2)
        let result = try await factor.calculate(context: makeContext(activity: activity))
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.value, 0.65, "Sedentary day → high stress contribution")
    }

    func testPostWorkout_suppressesStress() async throws {
        // Workout ended 30 min ago → 0.5h / 2.0 = 0.25 multiplier, clamped to max(0.3, 0.25) = 0.3
        let workoutEnd = Date().addingTimeInterval(-1800)
        let activity = makeActivity(steps: 500, energy: 20, standHours: 2, workoutEnd: workoutEnd)
        let result = try await factor.calculate(context: makeContext(activity: activity))
        XCTAssertNotNil(result)

        let noWorkoutActivity = makeActivity(steps: 500, energy: 20, standHours: 2)
        let noWorkoutResult = try await factor.calculate(context: makeContext(activity: noWorkoutActivity))
        XCTAssertNotNil(noWorkoutResult)

        XCTAssertLessThan(result!.value, noWorkoutResult!.value, "Post-workout suppresses raw stress score")
    }

    func testPostWorkoutExpired_noSuppression() async throws {
        // Workout ended 3h ago → beyond 2h window, no suppression
        let workoutEnd = Date().addingTimeInterval(-10800)
        let withExpired = makeActivity(steps: 500, energy: 20, standHours: 2, workoutEnd: workoutEnd)
        let withoutWorkout = makeActivity(steps: 500, energy: 20, standHours: 2)

        let expired = try await factor.calculate(context: makeContext(activity: withExpired))
        let noWorkout = try await factor.calculate(context: makeContext(activity: withoutWorkout))

        XCTAssertNotNil(expired)
        XCTAssertNotNil(noWorkout)
        XCTAssertEqual(expired!.value, noWorkout!.value, accuracy: 0.01,
                       "Expired workout window → no suppression applied")
    }

    func testConfidence_isFixed() async throws {
        let result = try await factor.calculate(context: makeContext(activity: makeActivity()))
        XCTAssertEqual(result!.confidence, 0.85, accuracy: 0.01)
    }

    func testOutputAlwaysInRange() async throws {
        let cases: [(Int, Double, Int)] = [
            (0, 0, 0), (2000, 50, 3), (5000, 150, 5), (8000, 250, 8), (10000, 300, 10)
        ]
        for (steps, energy, stand) in cases {
            let activity = makeActivity(steps: steps, energy: energy, standHours: stand)
            let result = try await factor.calculate(context: makeContext(activity: activity))
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.value, 0.0)
                XCTAssertLessThanOrEqual(r.value, 1.0)
            }
        }
    }
}
