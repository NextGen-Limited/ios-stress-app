import SwiftUI
import SwiftData

@Observable
class DetailViewModel {
    let measurement: StressMeasurement
    var baseline: PersonalBaseline?
    var todayAverage: Double?
    var weeklyAverage: Double?
    var trend: TrendDirection?
    var percentile: Double?
    var contributingFactors: [ContributingFactor] = []
    var recommendations: [Recommendation] = []

    private let repository: StressRepositoryProtocol

    init(measurement: StressMeasurement, modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.measurement = measurement
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
    }

    func loadData() async {
        do {
            async let bl = repository.getBaseline()
            async let today = repository.fetchAverageHRV(hours: 24)
            async let week = repository.fetchAverageHRV(days: 7)

            baseline = try await bl
            todayAverage = try await today
            weeklyAverage = try await week

            trend = calculateTrend()
            percentile = calculatePercentile()

            contributingFactors = generateContributingFactors()
            recommendations = generateRecommendations()
        } catch {}
    }

    var category: StressCategory {
        switch measurement.stressLevel {
        case 0...25: return .relaxed
        case 26...50: return .mild
        case 51...75: return .moderate
        default: return .high
        }
    }

    func shareMeasurement() {
        let text = """
        Stress Measurement - \(formatDate(measurement.timestamp))

        Stress Level: \(Int(measurement.stressLevel))/100
        HRV: \(Int(measurement.hrv)) ms
        Category: \(categoryTitle(category))
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func calculateTrend() -> TrendDirection {
        guard let today = todayAverage else { return .stable }
        let diff = measurement.hrv - today
        if diff > 5 { return .up }
        if diff < -5 { return .down }
        return .stable
    }

    private func calculatePercentile() -> Double {
        guard let baseline = baseline else { return 50 }
        let lowerBound = baseline.baselineHRV - 10
        let upperBound = baseline.baselineHRV + 10
        let normalized = (measurement.hrv - lowerBound) / (upperBound - lowerBound)
        return max(0, min(100, normalized * 100))
    }

    private func generateContributingFactors() -> [ContributingFactor] {
        return [
            ContributingFactor(
                name: "HRV Deviation",
                value: calculateHRVDeviation(),
                category: .high,
                label: "Higher than avg = Good"
            ),
            ContributingFactor(
                name: "Resting HR",
                value: 0.45,
                category: .normal,
                label: "Normal"
            ),
            ContributingFactor(
                name: "Sleep Quality",
                value: 0.60,
                category: .fair,
                label: "(7h 23m)"
            ),
            ContributingFactor(
                name: "Recent Activity",
                value: 0.30,
                category: .low,
                label: "(45 min workout)"
            )
        ]
    }

    private func calculateHRVDeviation() -> Double {
        guard let baseline = baseline else { return 0.5 }
        let lowerBound = baseline.baselineHRV - 10
        let upperBound = baseline.baselineHRV + 10
        let normalized = (measurement.hrv - lowerBound) / (upperBound - lowerBound)
        return max(0, min(1, normalized))
    }

    private func generateRecommendations() -> [Recommendation] {
        switch category {
        case .high:
            return [
                Recommendation(
                    title: "Breathing Exercise",
                    description: "Take a 5-minute resonance breathing break",
                    icon: "wind",
                    action: .breathing
                ),
                Recommendation(
                    title: "Hydration",
                    description: "Drink a glass of water to support recovery",
                    icon: "drop",
                    action: .hydration
                )
            ]
        case .moderate:
            return [
                Recommendation(
                    title: "Short Walk",
                    description: "A 10-minute walk can help reduce stress",
                    icon: "figure.walk",
                    action: .walk
                )
            ]
        default:
            return [
                Recommendation(
                    title: "Keep it up!",
                    description: "Your stress is well-managed today",
                    icon: "checkmark.circle.fill",
                    action: .none
                )
            ]
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, YYYY"
        return formatter.string(from: date)
    }
}

struct ContributingFactor {
    let name: String
    let value: Double
    let category: FactorCategory
    let label: String
}

enum FactorCategory {
    case low, normal, fair, high
}

struct Recommendation {
    let title: String
    let description: String
    let icon: String
    let action: RecommendationAction
}

enum RecommendationAction {
    case breathing
    case hydration
    case walk
    case none
}

func categoryTitle(_ category: StressCategory) -> String {
    switch category {
    case .relaxed: return "Relaxed"
    case .mild: return "Mild"
    case .moderate: return "Elevated"
    case .high: return "High"
    }
}

func iconForCategory(_ category: StressCategory) -> String {
    Color.stressIcon(for: category)
}

func colorForCategory(_ category: StressCategory) -> Color {
    Color.stressColor(for: category)
}

func trendIcon(_ trend: TrendDirection) -> String {
    switch trend {
    case .up: return "arrow.up"
    case .down: return "arrow.down"
    case .stable: return "minus"
    }
}

func trendColor(_ trend: TrendDirection) -> Color {
    switch trend {
    case .up: return .stressRelaxed
    case .down: return .stressHigh
    case .stable: return .secondary
    }
}
