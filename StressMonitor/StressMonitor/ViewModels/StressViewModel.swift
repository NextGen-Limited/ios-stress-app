import Foundation
import Observation
import HealthKit

@Observable
@MainActor
final class StressViewModel {

    var currentStress: StressResult?
    var historicalData: [StressMeasurement] = []
    var baseline: PersonalBaseline?
    var liveHeartRate: Double?
    var isLoading = false
    var errorMessage: String?
    var lastRefresh: Date?

    // MARK: - New Properties for Dashboard Enhancement

    /// Last 7 HRV readings for mini chart
    var hrvHistory: [Double] = []
    /// Heart rate trend direction
    var heartRateTrend: TrendDirection = .stable
    /// Today's measurements for timeline
    var todayMeasurements: [StressMeasurement] = []
    /// Current week average stress
    var weeklyCurrentAvg: Double = 0
    /// Previous week average stress
    var weeklyPreviousAvg: Double = 0
    /// AI-generated insight
    var aiInsight: AIInsight?

    // MARK: - Auto-Refresh Properties

    /// Last refresh time for debounce
    private var lastRefreshTime: Date?
    /// Minimum interval between refreshes (60 seconds)
    private let refreshInterval: TimeInterval = 60
    /// HealthKit observer query for HRV
    private var observerQuery: HKObserverQuery?
    /// HealthStore instance
    private let healthStore = HKHealthStore()

    // MARK: - Trend Direction

    enum TrendDirection {
        case up, down, stable
    }

    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    /// Stored Task for heart rate observation cancellation
    private var heartRateTask: Task<Void, Never>?

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func loadCurrentStress() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 1)

            let (hrvData, hrData) = try await (hrv, hr)

            guard let hrvValue = hrvData?.value else {
                errorMessage = "No HRV data available"
                return
            }

            let heartRateValue = hrData.first?.value ?? 70

            let result = try await algorithm.calculateStress(hrv: hrvValue, heartRate: heartRateValue)
            currentStress = result
            lastRefresh = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadHistoricalData(days: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            historicalData = try await repository.fetchRecent(limit: days * 24)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBaseline() async {
        isLoading = true
        defer { isLoading = false }

        do {
            baseline = try await repository.getBaseline()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshHealthData() async {
        await loadCurrentStress()
    }

    func observeHeartRate() {
        heartRateTask = Task {
            for await sample in healthKit.observeHeartRateUpdates() {
                liveHeartRate = sample?.value
            }
        }
    }

    func calculateAndSaveStress() async throws {
        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 1)

        let (hrvData, hrData) = try await (hrv, hr)

        guard let hrvValue = hrvData?.value else {
            throw StressError.noData
        }

        let heartRateValue = hrData.first?.value ?? 70
        let result = try await algorithm.calculateStress(hrv: hrvValue, heartRate: heartRateValue)

        let measurement = StressMeasurement(
            timestamp: result.timestamp,
            stressLevel: result.level,
            hrv: result.hrv,
            restingHeartRate: result.heartRate,
            confidences: [result.confidence]
        )

        try await repository.save(measurement)
        currentStress = result
        lastRefresh = Date()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Dashboard Data Loading

    /// Load all dashboard data in one call
    func loadDashboardData() async {
        await loadCurrentStress()
        await loadHistoricalData(days: 14)
        loadTodayMeasurements()
        loadWeeklyComparison()
        generateInsight()
    }

    /// Load today's measurements for timeline view
    func loadTodayMeasurements() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        todayMeasurements = historicalData.filter { $0.timestamp >= startOfDay }
        hrvHistory = Array(todayMeasurements.map { $0.hrv }.suffix(7))
    }

    /// Calculate current vs previous week averages
    func loadWeeklyComparison() {
        let calendar = Calendar.current
        let now = Date()

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) else {
            weeklyCurrentAvg = 0
            weeklyPreviousAvg = 0
            return
        }

        let currentWeek = historicalData.filter { $0.timestamp >= weekStart }
        let prevWeek = historicalData.filter { $0.timestamp >= prevWeekStart && $0.timestamp < weekStart }

        weeklyCurrentAvg = currentWeek.isEmpty ? 0 : currentWeek.map(\.stressLevel).reduce(0, +) / Double(currentWeek.count)
        weeklyPreviousAvg = prevWeek.isEmpty ? 0 : prevWeek.map(\.stressLevel).reduce(0, +) / Double(prevWeek.count)
    }

    /// Generate AI insight from current stress and history
    func generateInsight() {
        guard let stress = currentStress else {
            aiInsight = nil
            return
        }
        aiInsight = InsightGenerator.generate(from: stress, history: historicalData)
    }

    // MARK: - Auto-Refresh with HKObserverQuery

    /// Check if enough time has passed for a refresh
    private var canRefresh: Bool {
        guard let last = lastRefreshTime else { return true }
        return Date().timeIntervalSince(last) >= refreshInterval
    }

    /// Start auto-refresh via HealthKit observer
    func startAutoRefresh() {
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, error in
            guard let self else {
                completionHandler()
                return
            }

            if let error = error {
                Task { @MainActor [weak self] in
                    self?.errorMessage = "HealthKit observer error: \(error.localizedDescription)"
                }
                completionHandler()
                return
            }

            Task { @MainActor [weak self] in
                self?.handleHealthKitUpdate()
            }

            completionHandler()
        }

        healthStore.execute(query)
        observerQuery = query
    }

    /// Stop auto-refresh observer
    func stopAutoRefresh() {
        // Cancel HKObserverQuery
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
        // Cancel heart rate observation Task
        heartRateTask?.cancel()
        heartRateTask = nil
    }

    /// Handle HealthKit update with debounce
    private func handleHealthKitUpdate() {
        guard canRefresh else { return }

        let previousCategory = currentStress?.category

        Task {
            await loadCurrentStress()
            loadTodayMeasurements()
            generateInsight()

            // Haptic feedback on category change
            if let newCategory = currentStress?.category,
               newCategory != previousCategory {
                HapticManager.shared.stressLevelChanged(to: newCategory)
            }

            lastRefreshTime = Date()
        }
    }
}

enum StressError: Error {
    case noData
}
