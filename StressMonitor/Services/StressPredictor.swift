import Foundation
import CoreML

/// Enhanced stress predictor that uses HRVAnalyzer for real-time scoring.
/// Falls back to heuristic when CoreML model is unavailable.
@MainActor
class StressPredictor: ObservableObject {
    private var model: MLModel?

    // MARK: - Published State

    @Published var currentScore: Double = 0.0
    @Published var currentCategory: HRVAnalyzer.StressCategory = .resting
    @Published var coherence: Double = 0.0
    @Published var lastAnalysis: HRVAnalyzer.AnalysisResult?

    // MARK: - Baseline Tracking

    /// Rolling 7-day baseline HRV (SDNN in ms). Updated from historical data.
    @Published var baselineHRV: Double = 60.0

    /// Rolling baseline heart rate
    @Published var baselineHeartRate: Double = 65.0

    /// Recent stress scores for trend computation
    private(set) var recentScores: [(timestamp: Date, score: Double)] = []
    private let maxRecentScores = 100

    init() {
        loadModel()
    }

    // MARK: - Public API

    /// Analyze real-time HRV data and produce a stress score.
    /// This is the primary entry point for live monitoring.
    func analyzeRealTime(rrIntervals: [Double]) -> HRVAnalyzer.AnalysisResult? {
        guard let result = HRVAnalyzer.analyze(rrIntervals: rrIntervals) else {
            return nil
        }

        // Update published state
        currentScore = result.stressScore
        currentCategory = result.stressCategory
        coherence = result.coherenceScore
        lastAnalysis = result

        // Track for trend
        recentScores.append((timestamp: Date(), score: result.stressScore))
        if recentScores.count > maxRecentScores {
            recentScores.removeFirst(recentScores.count - maxRecentScores)
        }

        return result
    }

    /// Quick stress score from HealthKit summary data (SDNN + HR).
    /// Used when we only have aggregated HealthKit samples, not raw RR intervals.
    func quickScore(hrvSDNN: Double, heartRate: Double) -> Double {
        let score = HRVAnalyzer.quickStressScore(
            hrvSDNN: hrvSDNN,
            heartRate: heartRate,
            baselineHRV: baselineHRV
        )

        currentScore = score
        currentCategory = categorize(score: score)

        recentScores.append((timestamp: Date(), score: score))
        if recentScores.count > maxRecentScores {
            recentScores.removeFirst(recentScores.count - maxRecentScores)
        }

        return score
    }

    /// Update baselines from historical HealthKit data.
    func updateBaselines(averageHRV: Double, averageHeartRate: Double) {
        baselineHRV = averageHRV
        baselineHeartRate = averageHeartRate
    }

    /// Stress trend over recent readings. Positive = stress increasing.
    var trendSlope: Double {
        guard recentScores.count >= 3 else { return 0 }
        let recent = recentScores.suffix(10)
        let scores = recent.map { $0.score }
        let n = Double(scores.count)
        let xMean = (n - 1) / 2.0
        let yMean = scores.reduce(0, +) / n

        var numerator: Double = 0
        var denominator: Double = 0
        for (i, s) in scores.enumerated() {
            let x = Double(i) - xMean
            numerator += x * (s - yMean)
            denominator += x * x
        }

        return denominator > 0 ? numerator / denominator : 0
    }

    /// Average stress score over the last N readings.
    func averageScore(last n: Int = 10) -> Double {
        let slice = recentScores.suffix(n).map { $0.score }
        guard !slice.isEmpty else { return 0 }
        return slice.reduce(0, +) / Double(slice.count)
    }

    // MARK: - Private

    private func loadModel() {
        // TODO: Load CoreML model when available
        // model = try? StressClassifier(configuration: MLModelConfiguration()).model
    }

    private func categorize(score: Double) -> HRVAnalyzer.StressCategory {
        switch score {
        case 0.0..<0.2:  return .resting
        case 0.2..<0.4:  return .low
        case 0.4..<0.6:  return .moderate
        case 0.6..<0.8:  return .high
        default:          return .veryHigh
        }
    }
}
