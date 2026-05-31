#if DEBUG
import Foundation

// MARK: - SimulatorHealthKitService

/// Dynamic HealthKit data generator for simulator demo mode.
/// Cycles through 5 stress scenarios every ~30s, producing realistic
/// time-varying data for all 5 factors (HRV, HR, Sleep, Activity, Recovery).
/// Activated via `-demo-mode` launch argument.
final class SimulatorHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {

    private let startTime = Date()
    private let scenarioDuration: TimeInterval = 30

    // MARK: - Stress Scenarios

    private enum Scenario: Int, CaseIterable {
        case relaxed, mild, moderate, high, edgeLowHRV

        var hrvRange: ClosedRange<Double> {
            switch self {
            case .relaxed:    return 55...80
            case .mild:       return 38...55
            case .moderate:   return 25...38
            case .high:       return 15...25
            case .edgeLowHRV: return 10...18
            }
        }

        var hrRange: ClosedRange<Double> {
            switch self {
            case .relaxed:    return 55...68
            case .mild:       return 68...80
            case .moderate:   return 80...95
            case .high:       return 95...115
            case .edgeLowHRV: return 100...115
            }
        }
    }

    private var currentScenario: Scenario {
        let elapsed = Date().timeIntervalSince(startTime)
        let index = Int(elapsed / scenarioDuration) % Scenario.allCases.count
//        return Scenario(rawValue: index) ?? .relaxed
        return .edgeLowHRV
    }

    // MARK: - Core Data Generation

    private func currentHRV() -> Double {
        let scenario = currentScenario
        let base = (scenario.hrvRange.lowerBound + scenario.hrvRange.upperBound) / 2
        let time = Date().timeIntervalSince1970
        let noise = sin(time * 0.7) * 3
        let jitter = Double.random(in: -2...2)
        return max(10, min(90, base + noise + jitter))
    }

    private func currentHeartRate() -> Double {
        let scenario = currentScenario
        let base = (scenario.hrRange.lowerBound + scenario.hrRange.upperBound) / 2
        let time = Date().timeIntervalSince1970
        let noise = cos(time * 0.5) * 2
        let jitter = Double.random(in: -3...3)
        return max(40, min(180, base + noise + jitter))
    }

    // MARK: - HealthKitServiceProtocol

    func requestAuthorization() async throws {}

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        // 5% chance nil — simulates missing data
        guard Double.random(in: 0...1) >= 0.05 else { return nil }
        return HRVMeasurement(value: currentHRV(), timestamp: Date())
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        let baseHR = currentHeartRate()
        return (0..<max(1, samples)).map { i in
            HeartRateSample(
                value: max(40, baseHR + Double.random(in: -2...2)),
                timestamp: Date().addingTimeInterval(Double(-i) * 30)
            )
        }
    }

    func fetchHRVHistory(since date: Date) async throws -> [HRVMeasurement] {
        generateHistoricalData(since: date)
    }

    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    continuation.yield(HeartRateSample(value: self.currentHeartRate(), timestamp: Date()))
                    try? await Task.sleep(for: .seconds(Double.random(in: 3...5)))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Multi-Factor Data

    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let scenario = currentScenario
        guard scenario != .edgeLowHRV else { return nil }
        return makeSleepData(scenario, date: date)
    }

    func fetchActivityData(for date: Date) async throws -> ActivityData? {
        let scenario = currentScenario
        guard scenario != .edgeLowHRV else { return nil }
        return makeActivityData(scenario, date: date)
    }

    func fetchRecoveryData(for date: Date) async throws -> RecoveryData? {
        let scenario = currentScenario
        if scenario == .edgeLowHRV {
            // Partial data — some sub-metrics nil
            return RecoveryData(respiratoryRate: 22, bloodOxygen: nil,
                               restingHeartRate: 85, restingHRTrend: nil, analysisDate: date)
        }
        return makeRecoveryData(scenario, date: date)
    }

    // MARK: - Sleep Generation (table-driven)

    private func makeSleepData(_ s: Scenario, date: Date) -> SleepData {
        let (tR, dR, rR, aR, eR): (ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Int>, ClosedRange<Double>) = switch s {
        case .relaxed:    (7.5...8.5, 1.3...1.7, 1.8...2.2, 0...1,  0.90...0.95)
        case .mild:       (6.0...7.0, 0.8...1.2, 1.3...1.7, 1...2,  0.80...0.90)
        case .moderate:   (5.0...6.0, 0.3...0.7, 0.8...1.2, 3...5,  0.70...0.80)
        case .high:       (3.0...5.0, 0.1...0.3, 0.3...0.6, 5...8,  0.55...0.70)
        case .edgeLowHRV: (4.0...4.0, 0.2...0.2, 0.5...0.5, 6...6,  0.55...0.60)
        }
        let total = Double.random(in: tR), deep = Double.random(in: dR), rem = Double.random(in: rR)
        let eff = Double.random(in: eR)
        return SleepData(totalSleepHours: total, deepSleepHours: deep, remSleepHours: rem,
                         coreSleepHours: max(0, total - deep - rem), awakenings: Int.random(in: aR),
                         timeInBedHours: total / eff, sleepEfficiency: eff, analysisDate: date)
    }

    // MARK: - Activity Generation (table-driven)

    private func makeActivityData(_ s: Scenario, date: Date) -> ActivityData {
        let (steps, kcal, stand, hasWorkout): (ClosedRange<Int>, ClosedRange<Double>, ClosedRange<Int>, Bool) = switch s {
        case .relaxed:    (8000...12000, 300...500, 10...12, true)
        case .mild:       (5000...8000,  200...300, 7...9,   false)
        case .moderate:   (2000...5000,  100...200, 4...6,   false)
        case .high:       (500...2000,   50...100,  2...3,   false)
        case .edgeLowHRV: (0...500,      0...30,    0...1,   false)
        }
        return ActivityData(
            stepCount: Int.random(in: steps), activeEnergyKcal: Double.random(in: kcal),
            standHours: Int.random(in: stand),
            lastWorkoutEndTime: hasWorkout ? date.addingTimeInterval(-3600) : nil,
            lastWorkoutDurationMinutes: hasWorkout ? Double.random(in: 30...60) : nil,
            analysisDate: date
        )
    }

    // MARK: - Recovery Generation (table-driven)

    private func makeRecoveryData(_ s: Scenario, date: Date) -> RecoveryData {
        let (rr, spo2, rhr, trend): (ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>) = switch s {
        case .relaxed:    (14...16, 97...99, 55...62, -3...(-1))
        case .mild:       (16...18, 96...98, 62...68, -1...1)
        case .moderate:   (18...20, 95...97, 68...75, 1...3)
        case .high:       (20...24, 93...96, 75...85, 3...8)
        case .edgeLowHRV: (20...24, 93...96, 80...90, 5...10)
        }
        return RecoveryData(
            respiratoryRate: Double.random(in: rr), bloodOxygen: Double.random(in: spo2),
            restingHeartRate: Double.random(in: rhr), restingHRTrend: Double.random(in: trend),
            analysisDate: date
        )
    }

    // MARK: - Historical Data Generation

    private func generateHistoricalData(since date: Date) -> [HRVMeasurement] {
        let calendar = Calendar.current
        let now = Date()
        var measurements: [HRVMeasurement] = []
        var currentDate = date
        var dayTrend: Double = 0

        while currentDate <= now {
            let count = Int.random(in: 3...5)
            for i in 0..<count {
                let hour = 7 + (16 * i / count) + Int.random(in: 0...1)
                guard let ts = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59),
                                             second: 0, of: currentDate),
                      ts <= now else { continue }

                // Circadian curve: higher morning/evening, lower midday
                let circadian = 1.0 + 0.15 * cos((Double(hour) - 8) * .pi / 8)
                let hrv = max(10, min(90, 50 * circadian + dayTrend + Double.random(in: -5...5)))
                measurements.append(HRVMeasurement(value: hrv, timestamp: ts))
            }

            dayTrend = max(-15, min(15, dayTrend + Double.random(in: -3...3)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        // Inject 1-2 edge case days (very low HRV)
        if measurements.count > 10 {
            for _ in 0..<2 {
                let idx = Int.random(in: 0..<measurements.count)
                let orig = measurements[idx]
                measurements[idx] = HRVMeasurement(value: Double.random(in: 12...18), timestamp: orig.timestamp)
            }
        }

        return measurements.sorted { $0.timestamp < $1.timestamp }
    }
}
#endif
