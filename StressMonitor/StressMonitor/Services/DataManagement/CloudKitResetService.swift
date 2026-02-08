import CloudKit
import Foundation
import os.log

// MARK: - CloudKit Reset Service
/// Handles deletion of CloudKit records and database reset operations
@MainActor
final class CloudKitResetService: Sendable {

    // MARK: - Properties

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private nonisolated let logger: DataManagementLogger

    // MARK: - Progress Tracking

    private var _isDeleting: ObserverIsolated<Bool> = ObserverIsolated(false)
    private var _deleteProgress: ObserverIsolated<Double> = ObserverIsolated(0.0)
    private var _currentOperation: ObserverIsolated<String?> = ObserverIsolated(nil)
    private var _recordsDeleted: ObserverIsolated<Int> = ObserverIsolated(0)

    var isDeleting: Bool { _isDeleting.wrappedValue }
    var deleteProgress: Double { _deleteProgress.wrappedValue }
    var currentOperation: String? { _currentOperation.wrappedValue }
    var recordsDeleted: Int { _recordsDeleted.wrappedValue }

    // MARK: - Initialization

    init(container: CKContainer = .default(), logger: DataManagementLogger = .default) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.logger = logger
    }

    // MARK: - Delete All Records

    /// Delete all CloudKit records across all record types
    /// - Parameters:
    ///   - confirmation: Optional confirmation callback before proceeding
    ///   - includeBaseline: Whether to also delete personal baseline records
    /// - Throws: CloudKitResetError if deletion fails
    func deleteAllRecords(
        confirmation: (() async -> Bool)? = nil,
        includeBaseline: Bool = true
    ) async throws {
        _isDeleting.wrappedValue = true
        _deleteProgress.wrappedValue = 0.0
        _recordsDeleted.wrappedValue = 0
        _currentOperation.wrappedValue = "Preparing CloudKit reset"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        // Request confirmation if callback provided
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                logger.log("CloudKit reset cancelled by user")
                throw CloudKitResetError.operationCancelled
            }
        }

        // Check account status first
        _currentOperation.wrappedValue = "Verifying iCloud account"
        _deleteProgress.wrappedValue = 0.05

        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            logger.log("iCloud account not available: \(accountStatus.rawValue)")
            throw CloudKitResetError.accountNotAvailable
        }

        // Delete each record type
        try await deleteRecords(ofType: .stressMeasurement, expectedProgress: 0.0...0.6)

        if includeBaseline {
            try await deleteRecords(ofType: .personalBaseline, expectedProgress: 0.6...0.8)
        }

        try await deleteRecords(ofType: .syncMetadata, expectedProgress: 0.8...0.95)

        _deleteProgress.wrappedValue = 1.0
        _currentOperation.wrappedValue = "CloudKit reset complete"
        logger.log("Successfully deleted \(_recordsDeleted.wrappedValue) CloudKit records")
    }

    // MARK: - Delete by Record Type

    /// Delete all records of a specific type
    /// - Parameter recordType: The CloudKit record type to delete
    /// - Throws: CloudKitResetError if deletion fails
    func deleteRecords(ofType recordType: CloudKitRecordType, expectedProgress: ClosedRange<Double> = 0.0...1.0) async throws {
        _currentOperation.wrappedValue = "Fetching \(recordType.rawValue) records"
        logger.log("Starting deletion of \(recordType.rawValue) records")

        do {
            // Query all records of this type
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)

            let (matchResults, queryCursor) = try await privateDatabase.records(matching: query)

            var recordsToDelete: [CKRecord.ID] = []
            var deletedCount = 0

            // Collect record IDs from initial results
            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    recordsToDelete.append(recordID)
                    deletedCount += 1
                case .failure(let error):
                    logger.log("Error fetching record: \(error.localizedDescription)")
                }
            }

            // Handle cursor if there are more records
            if let cursor = queryCursor {
                try await fetchRecordsWithCursor(cursor, accumalatingInto: &recordsToDelete)
            }

            guard !recordsToDelete.isEmpty else {
                logger.log("No \(recordType.rawValue) records found to delete")
                return
            }

            // Batch delete records
            _currentOperation.wrappedValue = "Deleting \(recordsToDelete.count) \(recordType.rawValue) records"
            _deleteProgress.wrappedValue = expectedProgress.lowerBound + (expectedProgress.upperBound - expectedProgress.lowerBound) * 0.5

            try await deleteBatchRecords(recordsToDelete, recordType: recordType)

            _recordsDeleted.wrappedValue += deletedCount
            _deleteProgress.wrappedValue = expectedProgress.upperBound

            logger.log("Successfully deleted \(deletedCount) \(recordType.rawValue) records")

        } catch let error as CKError {
            logger.log("CloudKit error deleting \(recordType.rawValue): \(error.localizedDescription)")
            throw CloudKitResetError.cloudKitError(adaptCloudKitError(error))
        } catch {
            logger.log("Failed to delete \(recordType.rawValue) records: \(error.localizedDescription)")
            throw CloudKitResetError.deletionFailed(underlying: error)
        }
    }

    // MARK: - Delete by Date Range

    /// Delete records within a specific date range
    /// - Parameters:
    ///   - recordType: The CloudKit record type
    ///   - range: Date range for deletion
    /// - Throws: CloudKitResetError if deletion fails
    func deleteRecords(ofType recordType: CloudKitRecordType, in range: ClosedRange<Date>) async throws {
        _isDeleting.wrappedValue = true
        _currentOperation.wrappedValue = "Finding \(recordType.rawValue) records in date range"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        do {
            let predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@",
                                       range.lowerBound as NSDate,
                                       range.upperBound as NSDate)
            let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)

            let (matchResults, queryCursor) = try await privateDatabase.records(matching: query)

            var recordsToDelete: [CKRecord.ID] = []

            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    recordsToDelete.append(recordID)
                case .failure(let error):
                    logger.log("Error fetching record: \(error.localizedDescription)")
                }
            }

            if let cursor = queryCursor {
                try await fetchRecordsWithCursor(cursor, accumalatingInto: &recordsToDelete)
            }

            guard !recordsToDelete.isEmpty else {
                logger.log("No \(recordType.rawValue) records found in date range")
                return
            }

            _currentOperation.wrappedValue = "Deleting \(recordsToDelete.count) records"
            try await deleteBatchRecords(recordsToDelete, recordType: recordType)

            _recordsDeleted.wrappedValue += recordsToDelete.count
            logger.log("Successfully deleted \(recordsToDelete.count) records in date range")

        } catch let error as CKError {
            throw CloudKitResetError.cloudKitError(adaptCloudKitError(error))
        } catch {
            throw CloudKitResetError.deletionFailed(underlying: error)
        }
    }

    // MARK: - Delete Before Date

    /// Delete records older than a specified date
    /// - Parameters:
    ///   - recordType: The CloudKit record type
    ///   - date: Cutoff date
    /// - Throws: CloudKitResetError if deletion fails
    func deleteRecords(ofType recordType: CloudKitRecordType, before date: Date) async throws {
        _isDeleting.wrappedValue = true
        _currentOperation.wrappedValue = "Finding \(recordType.rawValue) records before \(date)"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        do {
            let predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
            let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)

            let (matchResults, queryCursor) = try await privateDatabase.records(matching: query)

            var recordsToDelete: [CKRecord.ID] = []

            for (recordID, result) in matchResults {
                switch result {
                case .success:
                    recordsToDelete.append(recordID)
                case .failure(let error):
                    logger.log("Error fetching record: \(error.localizedDescription)")
                }
            }

            if let cursor = queryCursor {
                try await fetchRecordsWithCursor(cursor, accumalatingInto: &recordsToDelete)
            }

            guard !recordsToDelete.isEmpty else {
                logger.log("No \(recordType.rawValue) records found before \(date)")
                return
            }

            _currentOperation.wrappedValue = "Deleting \(recordsToDelete.count) records"
            try await deleteBatchRecords(recordsToDelete, recordType: recordType)

            _recordsDeleted.wrappedValue += recordsToDelete.count
            logger.log("Successfully deleted \(recordsToDelete.count) records before \(date)")

        } catch let error as CKError {
            throw CloudKitResetError.cloudKitError(adaptCloudKitError(error))
        } catch {
            throw CloudKitResetError.deletionFailed(underlying: error)
        }
    }

    // MARK: - Complete Database Reset

    /// Perform a complete database reset - deletes all records and clears local cache
    /// - Parameter confirmation: Optional confirmation callback
    /// - Throws: CloudKitResetError if reset fails
    func performDatabaseReset(confirmation: (() async -> Bool)? = nil) async throws {
        _currentOperation.wrappedValue = "Starting complete database reset"

        // Delete all records including baseline
        try await deleteAllRecords(confirmation: confirmation, includeBaseline: true)

        _currentOperation.wrappedValue = "Database reset complete"
        logger.log("Complete database reset finished")
    }

    // MARK: - Helper Methods

    /// Fetch additional records using query cursor
    private func fetchRecordsWithCursor(
        _ cursor: CKQueryOperation.Cursor,
        accumalatingInto records: inout [CKRecord.ID]
    ) async throws {
        var currentCursor = cursor
        let database = privateDatabase  // Capture non-isolated reference
        nonisolated(unsafe) let loggerRef = logger

        while true {
            let operation = CKQueryOperation(cursor: currentCursor)
            operation.desiredKeys = ["recordID"]

            var fetchedRecords: [CKRecord.ID] = []
            var resultCursor: CKQueryOperation.Cursor?

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.recordMatchedBlock = { recordID, result in
                    switch result {
                    case .success:
                        fetchedRecords.append(recordID)
                    case .failure(let error):
                        loggerRef.log("Error fetching record with cursor: \(error.localizedDescription)")
                    }
                }

                operation.queryResultBlock = { result in
                    switch result {
                    case .success(let cursor):
                        resultCursor = cursor
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }

                database.add(operation)
            }

            records.append(contentsOf: fetchedRecords)

            // If no more results, break
            if fetchedRecords.isEmpty {
                break
            }

            // Update cursor for next iteration
            guard let newCursor = resultCursor else {
                break
            }
            currentCursor = newCursor

            // Prevent infinite loops
            if records.count > 10000 {
                loggerRef.log("Reached safety limit while fetching records")
                break
            }
        }
    }

    /// Delete records in batches to avoid rate limiting
    private func deleteBatchRecords(
        _ recordIDs: [CKRecord.ID],
        recordType: CloudKitRecordType,
        batchSize: Int = 300
    ) async throws {
        let batches = stride(from: 0, to: recordIDs.count, by: batchSize).map {
            Array(recordIDs[$0..<min($0 + batchSize, recordIDs.count)])
        }

        var totalDeleted = 0
        let database = privateDatabase  // Capture non-isolated reference

        for (index, batch) in batches.enumerated() {
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: batch)
            operation.isAtomic = false

            let deletedInBatch = (try? await performModifyOperationHelper(operation: operation, database: database, batchCount: batch.count)) ?? batch.count
            totalDeleted += deletedInBatch

            // Update progress
            let progress = Double(index + 1) / Double(batches.count)
            _deleteProgress.wrappedValue = max(_deleteProgress.wrappedValue, progress)

            // Small delay between batches to avoid rate limiting
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        logger.log("Deleted \(totalDeleted) \(recordType.rawValue) records in \(batches.count) batches")
    }

    private nonisolated func performModifyOperationHelper(
        operation: CKModifyRecordsOperation,
        database: CKDatabase,
        batchCount: Int
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: batchCount)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    // MARK: - Error Adaptation

    private func adaptCloudKitError(_ error: CKError) -> CloudKitResetError {
        switch error.code {
        case .networkFailure, .networkUnavailable:
            return .networkUnavailable
        case .notAuthenticated:
            return .notAuthenticated
        case .quotaExceeded:
            return .quotaExceeded
        case .requestRateLimited:
            return .rateLimited
        case .zoneNotFound:
            return .zoneNotFound
        case .unknownItem:
            return .recordNotFound
        default:
            return .cloudKitError(error)
        }
    }

    // MARK: - Statistics

    /// Count records of a specific type
    /// - Parameter recordType: The record type to count
    /// - Returns: Number of records
    func countRecords(ofType recordType: CloudKitRecordType) async throws -> Int {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)
        let database = privateDatabase  // Capture non-isolated reference

        do {
            let (matchResults, queryCursor) = try await privateDatabase.records(matching: query)

            var count = matchResults.count

            if let cursor = queryCursor {
                var currentCursor = cursor
                while true {
                    // Use query operation to count
                    let operation = CKQueryOperation(cursor: currentCursor)
                    var hasMoreResults = false
                    var resultCursor: CKQueryOperation.Cursor?

                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        operation.recordMatchedBlock = { _, _ in
                            hasMoreResults = true
                        }

                        operation.queryResultBlock = { result in
                            switch result {
                            case .success(let cursor):
                                resultCursor = cursor
                            case .failure:
                                break
                            }
                            continuation.resume()
                        }

                        database.add(operation)
                    }

                    count += 1

                    if !hasMoreResults {
                        break
                    }

                    // Update cursor for next iteration
                    guard let newCursor = resultCursor else {
                        break
                    }
                    currentCursor = newCursor

                    if count > 10000 {
                        break
                    }
                }
            }

            return count

        } catch {
            logger.log("Failed to count records: \(error.localizedDescription)")
            return 0
        }
    }
}

// MARK: - CloudKit Reset Error

enum CloudKitResetError: Error {
    case deletionFailed(underlying: Error)
    case cloudKitError(Error)
    case operationCancelled
    case accountNotAvailable
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case rateLimited
    case zoneNotFound
    case recordNotFound

    var localizedDescription: String {
        switch self {
        case .deletionFailed(let error):
            return "Failed to delete CloudKit data: \(error.localizedDescription)"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .operationCancelled:
            return "Operation was cancelled"
        case .accountNotAvailable:
            return "iCloud account is not available"
        case .notAuthenticated:
            return "Not authenticated with iCloud"
        case .networkUnavailable:
            return "Network is unavailable"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .zoneNotFound:
            return "CloudKit zone not found"
        case .recordNotFound:
            return "Record not found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .accountNotAvailable:
            return "Please sign in to iCloud in Settings"
        case .notAuthenticated:
            return "Please sign in to iCloud"
        case .networkUnavailable:
            return "Please check your internet connection"
        case .quotaExceeded:
            return "Please free up space in iCloud or upgrade your storage plan"
        case .rateLimited:
            return "Please wait a few minutes before trying again"
        default:
            return nil
        }
    }
}

// MARK: - Checked Continuation


// MARK: - CloudKitRecordType Extension

extension CloudKitRecordType: Sendable {}
