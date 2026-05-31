import CloudKit
import Foundation
import Observation

@MainActor
@Observable
public final class CloudKitSyncEngine {
    // MARK: - Properties

    public private(set) var syncProgress: Double = 0.0
    public private(set) var isSyncing: Bool = false
    public private(set) var lastError: Error?

    private let cloudKitManager: CloudKitManager
    private let batchSize: Int
    private let maxRetries: Int
    private let baseRetryDelay: TimeInterval

    // MARK: - Initialization

    public init(
        cloudKitManager: CloudKitManager,
        batchSize: Int = 10,
        maxRetries: Int = 3,
        baseRetryDelay: TimeInterval = 1.0
    ) {
        self.cloudKitManager = cloudKitManager
        self.batchSize = batchSize
        self.maxRetries = maxRetries
        self.baseRetryDelay = baseRetryDelay
    }

    // MARK: - Upload Operations

    public func uploadMeasurements(_ measurements: [StressMeasurement]) async throws {
        guard !measurements.isEmpty else { return }

        isSyncing = true
        syncProgress = 0.0
        lastError = nil

        let batches = measurements.chunked(into: batchSize)
        let totalBatches = batches.count

        for (index, batch) in batches.enumerated() {
            var attempt = 0
            var lastError: Error?

            while attempt < maxRetries {
                do {
                    try await uploadBatch(batch)
                    syncProgress = Double(index + 1) / Double(totalBatches)
                    break
                } catch {
                    lastError = error
                    attempt += 1

                    if attempt < maxRetries {
                        let delay = baseRetryDelay * pow(2.0, Double(attempt))
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
            }

            if attempt >= maxRetries {
                self.lastError = lastError
                isSyncing = false
                throw lastError ?? CloudKitSyncError.uploadFailed
            }
        }

        isSyncing = false
    }

    private func uploadBatch(_ batch: [StressMeasurement]) async throws {
        let records = batch.map { measurement -> CKRecord in
            let record = CKRecord(recordType: CloudKitRecordType.stressMeasurement.rawValue)
            record["timestamp"] = measurement.timestamp
            record["stressLevel"] = measurement.stressLevel
            record["hrv"] = measurement.hrv
            record["restingHeartRate"] = measurement.restingHeartRate
            record["category"] = measurement.categoryRawValue
            record["confidences"] = measurement.confidences ?? []
            record["deviceID"] = cloudKitManager.deviceID
            record["isDeleted"] = false
            record["cloudKitModTime"] = Date()
            return record
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            CKContainer.default().privateCloudDatabase.add(operation)
        }
    }

    // MARK: - Download Operations

    public func downloadMeasurements(since date: Date? = nil) async throws -> [StressMeasurement] {
        isSyncing = true
        syncProgress = 0.0
        lastError = nil

        var attempt = 0
        var lastError: Error?

        while attempt < maxRetries {
            do {
                let measurements = try await cloudKitManager.fetchMeasurements(since: date)
                syncProgress = 1.0
                isSyncing = false
                return measurements
            } catch {
                lastError = error
                attempt += 1

                if attempt < maxRetries {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        self.lastError = lastError
        isSyncing = false
        throw lastError ?? CloudKitSyncError.downloadFailed
    }

    // MARK: - Bidirectional Sync

    public func sync(localMeasurements: [StressMeasurement]) async throws -> [StressMeasurement] {
        isSyncing = true
        syncProgress = 0.0
        lastError = nil

        do {
            // Step 1: Upload local measurements
            try await uploadMeasurements(localMeasurements)
            syncProgress = 0.5

            // Step 2: Download remote measurements
            let remoteMeasurements = try await downloadMeasurements()
            syncProgress = 1.0

            isSyncing = false
            return remoteMeasurements
        } catch {
            self.lastError = error
            isSyncing = false
            throw error
        }
    }

    // MARK: - Background Task Support

    public func performBackgroundSync() async throws {
        let startDate = Date()

        do {
            // Fetch last sync date or use 24 hours ago
            let sinceDate = cloudKitManager.lastSyncDate?.addingTimeInterval(-86400) ?? startDate.addingTimeInterval(-86400)
            _ = try await downloadMeasurements(since: sinceDate)

            // Process measurements would happen here
            // This is handled by SyncManager
        } catch {
            lastError = error
            throw error
        }
    }

    // MARK: - Reset

    public func reset() {
        syncProgress = 0.0
        isSyncing = false
        lastError = nil
    }
}

// MARK: - Batch Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Sync Errors

public enum CloudKitSyncError: Error, Sendable {
    case uploadFailed
    case downloadFailed
    case syncCancelled
    case backgroundTaskExpired

    public var localizedDescription: String {
        switch self {
        case .uploadFailed:
            return "Failed to upload measurements to iCloud"
        case .downloadFailed:
            return "Failed to download measurements from iCloud"
        case .syncCancelled:
            return "Sync operation was cancelled"
        case .backgroundTaskExpired:
            return "Background sync task expired"
        }
    }
}

