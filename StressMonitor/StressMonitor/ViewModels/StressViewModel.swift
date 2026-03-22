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
    var dataQualityInfo: DataQualityInfo?

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
    private let calibrator = FactorCalibrator()

    /// Stored Task for heart rate observation cancellation
    private var heartRateTask: Task<Void, Never>?

    #if DEBUG
    /// Demo mode periodic stress recalculation task
    private var demoRefreshTask: Task<Void, Never>?
    #endif

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
            let fetchedBaseline = try? await repository.getBaseline()
            let currentBaseline = baseline ?? fetchedBaseline ?? PersonalBaseline()

            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 1)
            let (hrvData, hrData) = try await (hrv, hr)

            guard let hrvValue = hrvData?.value else {
                errorMessage = "No HRV data available"
                return
            }

            // Secondary factors fetched with graceful degradation
            let sleepData = try? await healthKit.fetchSleepData(for: Date())
            let activityData = try? await healthKit.fetchActivityData(for: Date())
            let recoveryData = try? await healthKit.fetchRecoveryData(for: Date())

            let context = StressContext(
                baseline: currentBaseline,
                hrv: hrvValue,
                heartRate: hrData.first?.value ?? 70,
                sleepData: sleepData,
                activityData: activityData,
                recoveryData: recoveryData,
                lastReadingDate: hrvData?.timestamp
            )

            let result = try await algorithm.calculateMultiFactorStress(context: context)
            currentStress = result
            baseline = currentBaseline
            lastRefresh = Date()
            errorMessage = nil

            if let breakdown = result.factorBreakdown {
                dataQualityInfo = DataQualityInfo(from: breakdown, baseline: currentBaseline)
            }
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
            var loadedBaseline = try await repository.getBaseline()

            // Trigger calibration if we have enough historical data
            let measurements = try await repository.fetchRecent(limit: 200)
            if measurements.count >= 30 {
                let weights = calibrator.calibrate(from: measurements)
                let hourly = calibrator.calculateHourlyBaseline(from: measurements)
                loadedBaseline.factorWeights = weights
                loadedBaseline.hourlyHRVBaseline = hourly
                loadedBaseline.calibrationDate = Date()
                try await repository.updateBaseline(loadedBaseline)
            }

            baseline = loadedBaseline
            if let breakdown = currentStress?.factorBreakdown {
                dataQualityInfo = DataQualityInfo(from: breakdown, baseline: loadedBaseline)
            }
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
        let fetchedBaseline = try? await repository.getBaseline()
        let currentBaseline = baseline ?? fetchedBaseline ?? PersonalBaseline()

        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 1)
        let (hrvData, hrData) = try await (hrv, hr)

        guard let hrvValue = hrvData?.value else { throw StressError.noData }

        let sleepData = try? await healthKit.fetchSleepData(for: Date())
        let activityData = try? await healthKit.fetchActivityData(for: Date())
        let recoveryData = try? await healthKit.fetchRecoveryData(for: Date())

        let context = StressContext(
            baseline: currentBaseline,
            hrv: hrvValue,
            heartRate: hrData.first?.value ?? 70,
            sleepData: sleepData,
            activityData: activityData,
            recoveryData: recoveryData,
            lastReadingDate: hrvData?.timestamp
        )

        let result = try await algorithm.calculateMultiFactorStress(context: context)

        let measurement = StressMeasurement(
            timestamp: result.timestamp,
            stressLevel: result.level,
            hrv: result.hrv,
            restingHeartRate: result.heartRate,
            confidences: [result.confidence]
        )

        if let breakdown = result.factorBreakdown {
            measurement.hrvComponent = breakdown.hrvComponent
            measurement.hrComponent = breakdown.hrComponent
            measurement.sleepComponent = breakdown.sleepComponent
            measurement.activityComponent = breakdown.activityComponent
            measurement.recoveryComponent = breakdown.recoveryComponent
            measurement.dataCompleteness = breakdown.dataCompleteness
        }

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
        // Demo mode: timer-based refresh instead of HKObserverQuery
        #if DEBUG
        if DemoMode.isEnabled {
            startDemoAutoRefresh()
            return
        }
        #endif

        // Skip HealthKit observer in simulator — no HealthKit entitlement in sim builds
        #if targetEnvironment(simulator)
        return
        #else
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
        #endif
    }

    #if DEBUG
    /// Demo mode: periodic stress recalculation every 15s
    private func startDemoAutoRefresh() {
        demoRefreshTask?.cancel()
        demoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled, let self else { return }
                await self.loadCurrentStress()
                self.loadTodayMeasurements()
                self.generateInsight()
            }
        }
    }
    #endif

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
        #if DEBUG
        demoRefreshTask?.cancel()
        demoRefreshTask = nil
        #endif
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
