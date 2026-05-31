import Foundation
import SwiftData
import CloudKit
import os.log

/// Manages CloudKit sync with optimized merge operations.
///
/// Key optimizations over naive O(n) scan:
/// 1. Compound predicate on (timestamp, deviceID) for O(1) lookup per record
/// 2. `fetchLimit` on descriptors to prevent unbounded reads
/// 3. Cursor-based pagination for large dataset operations
/// 4. TTL-based baseline cache to avoid recomputation
@MainActor
final class CloudKitManager: ObservableObject {
    
    // MARK: - Types
    
    /// Cache entry for computed baselines with TTL
    private struct BaselineCache {
        let baseline: StressBaseline
        let computedAt: Date
        let ttl: TimeInterval
        
        var isExpired: Date.now.timeIntervalSince(computedAt) > ttl
    }
    
    /// Cached stress baseline statistics
    struct StressBaseline {
        let averageHRV: Double
        let averageHeartRate: Double
        let averageStressLevel: Double
        let sampleCount: Int
        let periodStart: Date
        let periodEnd: Date
    }
    
    // MARK: - Configuration
    
    /// Maximum records to fetch per query (prevents memory pressure)
    static let fetchBatchSize = 100
    
    /// TTL for cached baselines (5 minutes)
    static let baselineCacheTTL: TimeInterval = 300
    
    /// How far back to look for duplicates (prevents false negatives from clock skew)
    static let duplicateWindowSeconds: TimeInterval = 60
    
    // MARK: - Published State
    
    @Published var syncState: SyncState = .idle
    @Published var lastSyncDate: Date?
    @Published var syncedRecordCount: Int = 0
    
    enum SyncState: Equatable {
        case idle
        case syncing
        case error(String)
    }
    
    // MARK: - Private State
    
    private let logger = Logger(subsystem: "com.stressmonitor", category: "CloudKitSync")
    private let container: CKContainer
    private var baselineCache: [String: BaselineCache] = [:]
    
    // MARK: - Init
    
    init(container: CKContainer = .default()) {
        self.container = container
    }
    
    // MARK: - Optimized Merge
    
    /// Merge a single remote measurement into the local store.
    ///
    /// Uses compound predicate (timestamp ± window + deviceID) for O(1) lookup
    /// instead of fetching all records.
    ///
    /// - Parameters:
    ///   - remoteRecord: The CKRecord from CloudKit
    ///   - context: The SwiftData model context
    /// - Returns: Whether a new record was inserted (true) or merged/skipped (false)
    func mergeRemoteMeasurement(
        _ remoteRecord: CKRecord,
        context: ModelContext
    ) throws -> Bool {
        guard let timestamp = remoteRecord["timestamp"] as? Date,
              let deviceID = remoteRecord["deviceID"] as? String else {
            logger.warning("Skipping malformed remote record: missing timestamp or deviceID")
            return false
        }
        
        // OPTIMIZATION: Compound predicate narrows search to matching records only
        // Instead of FetchDescriptor<StressMeasurement>() with no predicate (O(n)),
        // we search for records within a time window from the same device.
        let windowStart = timestamp.addingTimeInterval(-Self.duplicateWindowSeconds)
        let windowEnd = timestamp.addingTimeInterval(Self.duplicateWindowSeconds)
        
        let predicate = #Predicate<StressMeasurement> { measurement in
            measurement.timestamp >= windowStart &&
            measurement.timestamp <= windowEnd &&
            measurement.deviceID == deviceID
        }
        
        var descriptor = FetchDescriptor<StressMeasurement>(
            predicate: predicate,
            sortBy: [.init(\.timestamp)]
        )
        
        // OPTIMIZATION: fetchLimit prevents reading more than needed
        // We only need to know if a matching record exists (0 or 1 result)
        descriptor.fetchLimit = 1
        
        let existing = try context.fetch(descriptor)
        
        if let match = existing.first {
            // Record exists — update if remote is newer
            if let remoteModified = remoteRecord.modificationDate,
               remoteModified > (match.lastSyncedAt ?? .distantPast) {
                match.stressLevel = remoteRecord["stressLevel"] as? Double ?? match.stressLevel
                match.hrv = remoteRecord["hrv"] as? Double ?? match.hrv
                match.heartRate = remoteRecord["heartRate"] as? Double ?? match.heartRate
                match.lastSyncedAt = .now
                match.cloudKitMetadata = try? NSKeyedArchiver.archivedData(
                    withRootObject: remoteRecord,
                    requiringSecureCoding: true
                )
                logger.debug("Updated existing measurement \(match.id) from remote")
            }
            return false
        } else {
            // New record — insert
            let measurement = StressMeasurement(
                id: UUID(uuidString: remoteRecord.recordID.recordName) ?? UUID(),
                timestamp: timestamp,
                deviceID: deviceID,
                stressLevel: remoteRecord["stressLevel"] as? Double ?? 0,
                hrv: remoteRecord["hrv"] as? Double ?? 0,
                heartRate: remoteRecord["heartRate"] as? Double ?? 0,
                source: remoteRecord["source"] as? String ?? "estimated",
                lastSyncedAt: .now,
                cloudKitMetadata: try? NSKeyedArchiver.archivedData(
                    withRootObject: remoteRecord,
                    requiringSecureCoding: true
                )
            )
            context.insert(measurement)
            logger.debug("Inserted new measurement from remote: \(measurement.id)")
            return true
        }
    }
    
    // MARK: - Batch Merge with Pagination
    
    /// Merge a batch of remote records with cursor-based pagination.
    ///
    /// Processes records in batches of `fetchBatchSize` to avoid memory pressure
    /// when syncing large datasets.
    ///
    /// - Parameters:
    ///   - records: All remote CKRecords to merge
    ///   - context: The SwiftData model context
    /// - Returns: Number of new records inserted
    func mergeRemoteBatch(
        _ records: [CKRecord],
        context: ModelContext
    ) throws -> Int {
        var insertedCount = 0
        
        // Process in batches to limit memory pressure
        let batches = records.chunked(into: Self.fetchBatchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            logger.info("Processing batch \(batchIndex + 1)/\(batches.count) (\(batch.count) records)")
            
            for record in batch {
                if try mergeRemoteMeasurement(record, context: context) {
                    insertedCount += 1
                }
            }
            
            // Save after each batch to prevent data loss on interruption
            if context.hasChanges {
                try context.save()
            }
        }
        
        return insertedCount
    }
    
    // MARK: - Paginated Fetch from CloudKit
    
    /// Fetch all records from CloudKit using cursor-based pagination.
    ///
    /// Uses CKQueryOperation with resultsLimit to fetch in pages,
    /// preventing memory spikes from loading all records at once.
    ///
    /// - Parameter sinceDate: Only fetch records modified after this date
    /// - Returns: All fetched CKRecords
    func fetchAllRemoteRecords(sinceDate: Date? = nil) async throws -> [CKRecord] {
        let database = container.privateCloudDatabase
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor? = nil
        var pageCount = 0
        
        repeat {
            let operation: CKQueryOperation
            
            if let cursor = cursor {
                operation = CKQueryOperation(cursor: cursor)
            } else {
                let query = CKQuery(
                    recordType: StressMeasurement.recordType,
                    predicate: sinceDate.map { 
                        NSPredicate(format: "modificationDate > %@", $0 as NSDate)
                    } ?? NSPredicate(value: true)
                )
                operation = CKQueryOperation(query: query)
            }
            
            // OPTIMIZATION: resultsLimit caps per-page fetch size
            operation.resultsLimit = Self.fetchBatchSize
            
            let pageRecords = try await withCheckedThrowingContinuation { continuation in
                var pageResults: [CKRecord] = []
                
                operation.recordMatchedBlock = { _, result in
                    if case .success(let record) = result {
                        pageResults.append(record)
                    }
                }
                
                operation.queryResultBlock = { result in
                    switch result {
                    case .success(let nextCursor):
                        continuation.resume(returning: (pageResults, nextCursor))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                database.add(operation)
            }
            
            let (records, nextCursor) = pageRecords
            allRecords.append(contentsOf: records)
            cursor = nextCursor
            pageCount += 1
            
            logger.info("Fetched page \(pageCount): \(records.count) records (total: \(allRecords.count))")
            
        } while cursor != nil
        
        return allRecords
    }
    
    // MARK: - Full Sync
    
    /// Perform a full sync cycle: fetch remote changes and merge locally.
    func performSync(context: ModelContext) async {
        guard syncState != .syncing else {
            logger.warning("Sync already in progress, skipping")
            return
        }
        
        syncState = .syncing
        
        do {
            // Fetch only records modified since last sync
            let remoteRecords = try await fetchAllRemoteRecords(
                sinceDate: lastSyncDate
            )
            
            logger.info("Fetched \(remoteRecords.count) remote records")
            
            let inserted = try mergeRemoteBatch(remoteRecords, context: context)
            
            syncedRecordCount += inserted
            lastSyncDate = .now
            syncState = .idle
            
            logger.info("Sync complete: \(inserted) new records inserted")
        } catch {
            syncState = .error(error.localizedDescription)
            logger.error("Sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Baseline Caching
    
    /// Compute stress baseline for a time period with TTL caching.
    ///
    /// Caches results for `baselineCacheTTL` seconds to avoid
    /// recomputing on every dashboard refresh.
    ///
    /// - Parameters:
    ///   - periodStart: Start of the baseline period
    ///   - periodEnd: End of the baseline period
    ///   - context: The SwiftData model context
    /// - Returns: Cached or freshly computed baseline
    func computeBaseline(
        from periodStart: Date,
        to periodEnd: Date,
        context: ModelContext
    ) throws -> StressBaseline {
        let cacheKey = "\(periodStart.timeIntervalSince1970)-\(periodEnd.timeIntervalSince1970)"
        
        // Check cache first
        if let cached = baselineCache[cacheKey], !cached.isExpired {
            logger.debug("Returning cached baseline for \(cacheKey)")
            return cached.baseline
        }
        
        // OPTIMIZATION: Predicate filters to the exact time window
        // instead of fetching all records and filtering in memory
        let predicate = #Predicate<StressMeasurement> { measurement in
            measurement.timestamp >= periodStart &&
            measurement.timestamp <= periodEnd
        }
        
        var descriptor = FetchDescriptor<StressMeasurement>(
            predicate: predicate,
            sortBy: [.init(\.timestamp)]
        )
        
        // No fetchLimit here — we need all records in the window for accurate stats
        // But the predicate ensures we only load what's needed
        
        let measurements = try context.fetch(descriptor)
        
        guard !measurements.isEmpty else {
            let emptyBaseline = StressBaseline(
                averageHRV: 0,
                averageHeartRate: 0,
                averageStressLevel: 0,
                sampleCount: 0,
                periodStart: periodStart,
                periodEnd: periodEnd
            )
            baselineCache[cacheKey] = BaselineCache(
                baseline: emptyBaseline,
                computedAt: .now,
                ttl: Self.baselineCacheTTL
            )
            return emptyBaseline
        }
        
        let totalHRV = measurements.reduce(0.0) { $0 + $1.hrv }
        let totalHR = measurements.reduce(0.0) { $0 + $1.heartRate }
        let totalStress = measurements.reduce(0.0) { $0 + $1.stressLevel }
        let count = Double(measurements.count)
        
        let baseline = StressBaseline(
            averageHRV: totalHRV / count,
            averageHeartRate: totalHR / count,
            averageStressLevel: totalStress / count,
            sampleCount: measurements.count,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        
        // Cache with TTL
        baselineCache[cacheKey] = BaselineCache(
            baseline: baseline,
            computedAt: .now,
            ttl: Self.baselineCacheTTL
        )
        
        logger.info("Computed baseline: \(measurements.count) samples, avg HRV \(baseline.averageHRV)")
        return baseline
    }
    
    // MARK: - Cache Management
    
    /// Clear expired entries from the baseline cache
    func pruneBaselineCache() {
        baselineCache = baselineCache.filter { !$0.value.isExpired }
    }
    
    /// Clear all cached baselines (e.g., on sign-out or data reset)
    func clearBaselineCache() {
        baselineCache.removeAll()
    }
}

// MARK: - Array Chunking

private extension Array {
    /// Split array into chunks of specified size for batch processing
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
