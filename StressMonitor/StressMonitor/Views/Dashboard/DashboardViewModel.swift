import Foundation
import Observation

@Observable
@MainActor
class DashboardViewModel {
    var currentStress: StressResult?
    var todayHRV: Double?
    var weeklyTrend: TrendDirection = .stable
    var baseline: PersonalBaseline?
    var aiInsight: AIInsight?
    var lastUpdated: Date?
    var isMeasuring = false
    var errorMessage: String?

    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func refreshStressLevel() async {
        guard !isMeasuring else { return }

        do {
            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 1)
            async let bl = repository.getBaseline()
            async let recentData = repository.fetchRecent(limit: 50)

            let (hrvData, hrData, baselineResult, weeklyData) = try await (hrv, hr, bl, recentData)

            guard let hrv = hrvData, let hr = hrData.first else {
                errorMessage = "No health data available"
                return
            }

            currentStress = try await algorithm.calculateStress(
                hrv: hrv.value,
                heartRate: hr.value
            )

            todayHRV = hrv.value
            baseline = baselineResult
            lastUpdated = Date()

            weeklyTrend = calculateTrend(from: weeklyData)
            aiInsight = generateInsight()

            let measurement = StressMeasurement(
                timestamp: Date(),
                stressLevel: currentStress!.level,
                hrv: hrv.value,
                restingHeartRate: hr.value,
                confidences: [currentStress!.confidence]
            )
            try await repository.save(measurement)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func measureNow() async {
        isMeasuring = true
        await refreshStressLevel()
        isMeasuring = false
    }

    var stressCategory: StressCategory {
        currentStress?.category ?? .mild
    }

    private func calculateTrend(from data: [StressMeasurement]) -> TrendDirection {
        guard data.count >= 2 else { return .stable }

        let hrvData = data.map { $0.hrv }
        let sampleCount = min(3, hrvData.count)
        let recent = hrvData.prefix(sampleCount).reduce(0, +) / Double(sampleCount)
        let older = hrvData.suffix(sampleCount).reduce(0, +) / Double(sampleCount)

        let diff = recent - older
        if diff > 5 { return .up }
        if diff < -5 { return .down }
        return .stable
    }

    private func generateInsight() -> AIInsight? {
        guard let stress = currentStress else { return nil }

        if stress.level > 75 {
            return AIInsight(
                title: "High Stress Detected",
                message: "Your stress is elevated. Consider a breathing exercise.",
                actionTitle: "Start Breathing",
                trendData: nil
            )
        } else if stress.level < 25 {
            return AIInsight(
                title: "Great Recovery",
                message: "Your HRV is excellent today. Keep up the good work!",
                actionTitle: nil,
                trendData: nil
            )
        } else {
            return AIInsight(
                title: "Stress is Normal",
                message: "Your stress level is within your typical range.",
                actionTitle: nil,
                trendData: nil
            )
        }
    }
}

enum TrendDirection {
    case up
    case down
    case stable
}
