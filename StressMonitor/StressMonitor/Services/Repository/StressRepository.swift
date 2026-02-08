import Foundation
import SwiftData
import CloudKit

@MainActor
final class StressRepository: StressRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private nonisolated let baselineCalculator: BaselineCalculator
    private let cloudKitManager: CloudKitServiceProtocol?

    private var cachedBaseline: PersonalBaseline?

    // MARK: - Sync Status Callbacks

    public var onSyncStatusChange: ((SyncStatus) -> Void)?
    public var onSyncError: ((Error) -> Void)?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        baselineCalculator: BaselineCalculator? = nil,
        cloudKitManager: CloudKitServiceProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.baselineCalculator = baselineCalculator ?? BaselineCalculator()
        self.cloudKitManager = cloudKitManager

        // Note: Observation of CloudKit sync status is handled through
        // the onSyncStatusChange callback property set by the caller
    }

    // MARK: - Save Operations

    func save(_ measurement: StressMeasurement) async throws {
        // Offline-first: Always save locally first
        modelContext.insert(measurement)

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }

        // Trigger CloudKit sync if available
        if let cloudKit = cloudKitManager {
            await syncMeasurementToCloudKit(measurement)
        }
    }

    func saveBatch(_ measurements: [StressMeasurement]) async throws {
        // Offline-first: Save all locally first
        for measurement in measurements {
            modelContext.insert(measurement)
        }

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }

        // Trigger CloudKit sync if available
        if let cloudKit = cloudKitManager {
            await syncBatchToCloudKit(measurements)
        }
    }

    // MARK: - Fetch Operations

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        var descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchAll() async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchUnsyncedMeasurements() async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { !$0.isSynced },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp >= from && $0.timestamp <= to },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    // MARK: - Delete Operations

    func delete(_ measurement: StressMeasurement) async throws {
        // Mark for deletion and sync first
        measurement.isSynced = false

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed(error)
        }

        // Delete from CloudKit if available
        if let cloudKit = cloudKitManager {
            do {
                try await cloudKit.deleteMeasurement(measurement)
                measurement.cloudKitRecordName = nil
            } catch {
                onSyncError?(error)
                // Continue with local deletion even if CloudKit fails
            }
        }

        // Delete from local store
        modelContext.delete(measurement)

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed(error)
        }
    }

    func deleteOlderThan(_ date: Date) async throws {
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp < date }
        )

        do {
            let oldMeasurements = try modelContext.fetch(descriptor)

            // Mark all for deletion first
            for measurement in oldMeasurements {
                measurement.isSynced = false
            }
            try modelContext.save()

            // Delete from CloudKit if available
            if let cloudKit = cloudKitManager {
                for measurement in oldMeasurements {
                    try? await cloudKit.deleteMeasurement(measurement)
                }
            }

            // Delete from local store
            for measurement in oldMeasurements {
                modelContext.delete(measurement)
            }
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed(error)
        }
    }

    func deleteAllMeasurements() async throws {
        let descriptor = FetchDescriptor<StressMeasurement>()
        let allMeasurements = try modelContext.fetch(descriptor)

        for measurement in allMeasurements {
            modelContext.delete(measurement)
        }
        try modelContext.save()
        cachedBaseline = nil
    }

    // MARK: - Baseline Operations

    func getBaseline() async throws -> PersonalBaseline {
        if let cached = cachedBaseline {
            return cached
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp >= thirtyDaysAgo }
        )

        let measurements = try modelContext.fetch(descriptor)

        let baseline: PersonalBaseline
        if measurements.isEmpty {
            baseline = PersonalBaseline()
        } else {
            let hrvMeasurements = measurements.map { HRVMeasurement(value: $0.hrv, timestamp: $0.timestamp) }
            baseline = try await baselineCalculator.calculateBaseline(from: hrvMeasurements)
        }

        cachedBaseline = baseline
        return baseline
    }

    func updateBaseline(_ baseline: PersonalBaseline) async throws {
        cachedBaseline = baseline
    }

    // MARK: - Statistics Operations

    func fetchAverageHRV(hours: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        let measurements = try await fetchMeasurements(from: startDate, to: Date())

        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
    }

    func fetchAverageHRV(days: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let measurements = try await fetchMeasurements(from: startDate, to: Date())

        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
    }

    // MARK: - CloudKit Sync Operations

    /// Sync all pending measurements to CloudKit
    func syncPendingMeasurements() async throws {
        guard let cloudKit = cloudKitManager else {
            throw RepositoryError.cloudKitUnavailable
        }

        let unsynced = try await fetchUnsyncedMeasurements()

        guard !unsynced.isEmpty else { return }

        onSyncStatusChange?(.syncing(progress: 0.0))

        for (index, measurement) in unsynced.enumerated() {
            let progress = Double(index) / Double(unsynced.count)
            onSyncStatusChange?(.syncing(progress: progress))

            await syncMeasurementToCloudKit(measurement)
        }

        onSyncStatusChange?(.success)
    }

    /// Fetch changes from CloudKit and merge with local data
    func fetchFromCloudKit(since date: Date? = nil) async throws {
        guard let cloudKit = cloudKitManager else {
            throw RepositoryError.cloudKitUnavailable
        }

        onSyncStatusChange?(.syncing(progress: 0.0))

        do {
            let remoteMeasurements = try await cloudKit.fetchMeasurements(since: date)

            for measurement in remoteMeasurements {
                await mergeRemoteMeasurement(measurement)
            }

            onSyncStatusChange?(.success)
        } catch let error as CKError {
            onSyncError?(adaptCloudKitError(error))
            throw adaptCloudKitError(error)
        }
    }

    /// Perform full bidirectional sync
    func performFullSync() async throws {
        guard let cloudKit = cloudKitManager else {
            throw RepositoryError.cloudKitUnavailable
        }

        onSyncStatusChange?(.syncing(progress: 0.0))

        // Step 1: Push pending local changes
        try await syncPendingMeasurements()

        // Step 2: Pull remote changes
        if let lastSync = cloudKit.lastSyncDate {
            try await fetchFromCloudKit(since: lastSync)
        } else {
            try await fetchFromCloudKit()
        }

        onSyncStatusChange?(.success)
    }

    /// Check CloudKit account status
    func checkCloudKitStatus() async throws -> CloudKitAccountStatus {
        guard let cloudKit = cloudKitManager else {
            throw RepositoryError.cloudKitUnavailable
        }

        return try await cloudKit.checkAccountStatus()
    }

    // MARK: - Private Helper Methods

    private func syncMeasurementToCloudKit(_ measurement: StressMeasurement) async {
        guard let cloudKit = cloudKitManager else { return }

        do {
            try await cloudKit.saveMeasurement(measurement)

            // Update measurement with CloudKit metadata
            measurement.isSynced = true
            measurement.cloudKitModTime = Date()

            // Generate record name if not exists
            if measurement.cloudKitRecordName == nil {
                measurement.cloudKitRecordName = generateRecordName(for: measurement)
            }

            try modelContext.save()
        } catch {
            onSyncError?(error)
            measurement.isSynced = false
        }
    }

    private func syncBatchToCloudKit(_ measurements: [StressMeasurement]) async {
        guard let cloudKit = cloudKitManager else { return }

        onSyncStatusChange?(.syncing(progress: 0.0))

        for (index, measurement) in measurements.enumerated() {
            let progress = Double(index) / Double(measurements.count)
            onSyncStatusChange?(.syncing(progress: progress))

            await syncMeasurementToCloudKit(measurement)
        }

        onSyncStatusChange?(.success)
    }

    private func mergeRemoteMeasurement(_ remote: StressMeasurement) async {
        // Check if local version exists - fetch all and filter in Swift
        // This is more reliable than complex predicates
        let descriptor = FetchDescriptor<StressMeasurement>()

        do {
            let allMeasurements = try modelContext.fetch(descriptor)
            let existing = allMeasurements.filter { 
                $0.timestamp == remote.timestamp && $0.deviceID == remote.deviceID 
            }

            if let local = existing.first {
                // Conflict resolution: Use most recent modification time
                if let remoteModTime = remote.cloudKitModTime,
                   let localModTime = local.cloudKitModTime,
                   remoteModTime > localModTime {
                    // Remote is newer - update local
                    local.stressLevel = remote.stressLevel
                    local.hrv = remote.hrv
                    local.restingHeartRate = remote.restingHeartRate
                    local.categoryRawValue = remote.categoryRawValue
                    local.confidences = remote.confidences
                    local.isSynced = true
                    local.cloudKitModTime = remote.cloudKitModTime
                    local.cloudKitRecordName = remote.cloudKitRecordName
                }
            } else {
                // No local version - insert remote
                modelContext.insert(remote)
                remote.isSynced = true
            }

            try modelContext.save()
        } catch {
            onSyncError?(error)
        }
    }

    private func generateRecordName(for measurement: StressMeasurement) -> String {
        "measurement-\(measurement.timestamp.timeIntervalSince1970)-\(measurement.deviceID)"
    }

    private func adaptCloudKitError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .networkFailure, .networkUnavailable:
            return .networkUnavailable(.noInternet)
        case .notAuthenticated:
            return .networkUnavailable(.iCloudNotSignedIn)
        case .quotaExceeded:
            return .networkUnavailable(.quotaExceeded)
        case .requestRateLimited:
            return .rateLimited
        case .zoneNotFound:
            return .zoneNotFound
        case .unknownItem:
            return .recordNotFound
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Repository Errors

public enum RepositoryError: Error, Sendable {
    case saveFailed(Error)
    case deleteFailed(Error)
    case cloudKitUnavailable
    case syncFailed(Error)

    public var localizedDescription: String {
        switch self {
        case .saveFailed(let error):
            return "Failed to save measurement: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete measurement: \(error.localizedDescription)"
        case .cloudKitUnavailable:
            return "CloudKit is not available"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }
}
