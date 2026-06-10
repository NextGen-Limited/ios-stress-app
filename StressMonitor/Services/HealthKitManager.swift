import Foundation
import HealthKit

/// Real-time HealthKit monitoring service.
/// Sets up observer queries for HRV and heart rate data, fetches recent samples,
/// and pipes data through StressPredictor for live scoring.
@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    // MARK: - Published State

    @Published var currentStressLevel: Double = 0.0
    @Published var hrvHistory: [Double] = []
    @Published var heartRateHistory: [Double] = []
    @Published var recentReadings: [StressReading] = []
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var lastHRV: Double = 0
    @Published var lastHeartRate: Double = 0
    @Published var lastUpdate: Date?

    // MARK: - Dependencies

    let predictor = StressPredictor()

    // MARK: - HealthKit Queries

    private var hrvObserverQuery: HKObserverQuery?
    private var heartRateObserverQuery: HKObserverQuery?
    private var hrvAnchor: HKQueryAnchor?
    private var heartRateAnchor: HKQueryAnchor?

    // MARK: - Configuration

    /// How far back to fetch historical data on first load
    private let historyHours = 24

    /// Maximum number of data points to keep in memory
    private let maxHistoryPoints = 200

    init() {
        checkAuthorization()
    }

    nonisolated deinit {
        // Can't call @MainActor methods from deinit; queries stop on dealloc anyway
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let types: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        try await healthStore.requestAuthorization(toShare: [], read: types)
        isAuthorized = true
    }

    private func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        let hrStatus = healthStore.authorizationStatus(for: hrType)

        isAuthorized = (hrvStatus == .sharingAuthorized || hrvStatus == .notDetermined)
                    && (hrStatus == .sharingAuthorized || hrStatus == .notDetermined)
    }

    // MARK: - Real-time Monitoring

    /// Start monitoring HRV and heart rate with observer queries.
    /// Observer queries wake the app when new HealthKit data arrives.
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }

        setupHRVObserver()
        setupHeartRateObserver()

        // Fetch initial historical data
        Task {
            await fetchInitialData()
        }

        isMonitoring = true
    }

    func stopMonitoring() {
        if let query = hrvObserverQuery {
            healthStore.stop(query)
        }
        if let query = heartRateObserverQuery {
            healthStore.stop(query)
        }
        hrvObserverQuery = nil
        heartRateObserverQuery = nil
        isMonitoring = false
    }

    // MARK: - Observer Queries

    private func setupHRVObserver() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Fetch new HRV samples using anchored query
            Task { [weak self] in
                await self?.fetchNewHRVSamples()
                completionHandler()
            }
        }

        hrvObserverQuery = query
        healthStore.execute(query)
    }

    private func setupHeartRateObserver() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let query = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            Task { [weak self] in
                await self?.fetchNewHeartRateSamples()
                completionHandler()
            }
        }

        heartRateObserverQuery = query
        healthStore.execute(query)
    }

    // MARK: - Anchored Queries (Incremental Fetch)

    private func fetchNewHRVSamples() async {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        let query = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: nil,
            anchor: hrvAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil, let samples = samples as? [HKQuantitySample] else { return }

            self.hrvAnchor = newAnchor

            Task { @MainActor [weak self] in
                guard let self else { return }
                for sample in samples {
                    let hrvValue = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                    self.hrvHistory.append(hrvValue)
                    self.lastHRV = hrvValue

                    // Create reading with quick score
                    let hrValue = self.lastHeartRate > 0 ? self.lastHeartRate : 70
                    let stressLevel = self.predictor.quickScore(hrvSDNN: hrvValue, heartRate: hrValue)
                    self.currentStressLevel = stressLevel
                    self.lastUpdate = Date()

                    let reading = StressReading(
                        id: UUID(),
                        timestamp: sample.startDate,
                        level: stressLevel,
                        hrv: hrvValue,
                        heartRate: hrValue,
                        source: .appleWatch
                    )
                    self.recentReadings.insert(reading, at: 0)
                }

                // Trim history
                if self.hrvHistory.count > self.maxHistoryPoints {
                    self.hrvHistory.removeFirst(self.hrvHistory.count - self.maxHistoryPoints)
                }
                if self.recentReadings.count > self.maxHistoryPoints {
                    self.recentReadings = Array(self.recentReadings.prefix(self.maxHistoryPoints))
                }
            }
        }

        healthStore.execute(query)
    }

    private func fetchNewHeartRateSamples() async {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: nil,
            anchor: heartRateAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil, let samples = samples as? [HKQuantitySample] else { return }

            self.heartRateAnchor = newAnchor

            Task { @MainActor [weak self] in
                guard let self else { return }
                for sample in samples {
                    let hrValue = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    self.heartRateHistory.append(hrValue)
                    self.lastHeartRate = hrValue
                }

                // Trim history
                if self.heartRateHistory.count > self.maxHistoryPoints {
                    self.heartRateHistory.removeFirst(self.heartRateHistory.count - self.maxHistoryPoints)
                }
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Initial Data Load

    /// Fetch historical data for the initial display.
    private func fetchInitialData() async {
        do {
            let hrvSamples = try await fetchHRVData(hours: historyHours)
            let hrSamples = try await fetchHeartRateData(hours: historyHours)

            await MainActor.run {
                // Process HRV samples
                for sample in hrvSamples {
                    let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                    hrvHistory.append(value)
                    lastHRV = value
                }

                // Process heart rate samples
                for sample in hrSamples {
                    let value = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    heartRateHistory.append(value)
                    lastHeartRate = value
                }

                // Compute initial stress score from most recent data
                if let latestHRV = hrvHistory.last, let latestHR = heartRateHistory.last {
                    currentStressLevel = predictor.quickScore(hrvSDNN: latestHRV, heartRate: latestHR)
                    lastUpdate = Date()
                }

                // Build recent readings from paired samples
                buildRecentReadings()
            }
        } catch {
            // Silently handle — user may not have data yet
            print("HealthKitManager: Initial fetch failed: \(error)")
        }
    }

    /// Fetch HRV data for the specified time window.
    func fetchHRVData(hours: Int = 24) async throws -> [HKQuantitySample] {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        return try await fetchQuantitySamples(type: hrvType, hours: hours)
    }

    /// Fetch heart rate data for the specified time window.
    func fetchHeartRateData(hours: Int = 24) async throws -> [HKQuantitySample] {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        return try await fetchQuantitySamples(type: hrType, hours: hours)
    }

    private func fetchQuantitySamples(type: HKQuantityType, hours: Int) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-Double(hours) * 3600),
            end: Date(),
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    /// Build recent readings from the loaded history data.
    private func buildRecentReadings() {
        // Pair HRV and heart rate samples by closest timestamp
        // For simplicity, create readings from HRV samples with the latest HR value
        var readings: [StressReading] = []
        for (idx, hrv) in hrvHistory.enumerated().reversed() {
            let hr = idx < heartRateHistory.count ? heartRateHistory[idx] : (heartRateHistory.last ?? 70)
            let stressLevel = HRVAnalyzer.quickStressScore(hrvSDNN: hrv, heartRate: hr, baselineHRV: predictor.baselineHRV)

            let reading = StressReading(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-Double(hrvHistory.count - idx) * 60),
                level: stressLevel,
                hrv: hrv,
                heartRate: hr,
                source: .appleWatch
            )
            readings.append(reading)

            if readings.count >= 20 { break }
        }

        recentReadings = readings
    }
}

// MARK: - HealthKit Error

enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case dataUnavailable
}
