import Foundation
import SwiftData
import os.log

// MARK: - Local Data Wipe Service
/// Handles batch deletion of stress measurements from SwiftData local storage
@MainActor
final class LocalDataWipeService: Sendable {

    // MARK: - Properties

    private let modelContext: ModelContext
    private nonisolated let logger: DataManagementLogger

    // MARK: - Progress Tracking

    private var _isDeleting: ObserverIsolated<Bool> = ObserverIsolated(false)
    private var _deleteProgress: ObserverIsolated<Double> = ObserverIsolated(0.0)
    private var _currentOperation: ObserverIsolated<String?> = ObserverIsolated(nil)

    var isDeleting: Bool { _isDeleting.wrappedValue }
    var deleteProgress: Double { _deleteProgress.wrappedValue }
    var currentOperation: String? { _currentOperation.wrappedValue }

    // MARK: - Initialization

    init(modelContext: ModelContext, logger: DataManagementLogger = .default) {
        self.modelContext = modelContext
        self.logger = logger
    }

    // MARK: - Delete Operations

    /// Delete all stress measurements from local storage
    /// - Parameter confirmation: Optional confirmation callback before proceeding
    /// - Throws: LocalDataError if deletion fails
    func deleteAllMeasurements(confirmation: (() async -> Bool)? = nil) async throws {
        _isDeleting.wrappedValue = true
        _deleteProgress.wrappedValue = 0.0
        _currentOperation.wrappedValue = "Preparing to delete all measurements"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        // Request confirmation if callback provided
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                logger.log("Deletion cancelled by user")
                throw LocalDataError.operationCancelled
            }
        }

        do {
            _currentOperation.wrappedValue = "Fetching all measurements"
            _deleteProgress.wrappedValue = 0.1

            let descriptor = FetchDescriptor<StressMeasurement>()
            let allMeasurements = try modelContext.fetch(descriptor)

            guard !allMeasurements.isEmpty else {
                logger.log("No measurements to delete")
                _deleteProgress.wrappedValue = 1.0
                return
            }

            _currentOperation.wrappedValue = "Deleting \(allMeasurements.count) measurements"
            logger.log("Deleting \(allMeasurements.count) measurements from local storage")

            let total = Double(allMeasurements.count)
            for (index, measurement) in allMeasurements.enumerated() {
                modelContext.delete(measurement)

                // Update progress every 10% or for the last item
                let progress = Double(index + 1) / total
                if progress > _deleteProgress.wrappedValue + 0.1 || index == allMeasurements.count - 1 {
                    _deleteProgress.wrappedValue = progress
                }
            }

            _currentOperation.wrappedValue = "Saving changes"
            _deleteProgress.wrappedValue = 0.9
            try modelContext.save()

            _deleteProgress.wrappedValue = 1.0
            logger.log("Successfully deleted all \(allMeasurements.count) measurements")

        } catch {
            logger.log("Failed to delete all measurements: \(error.localizedDescription)")
            throw LocalDataError.deletionFailed(underlying: error)
        }
    }

    /// Delete measurements older than a specified date
    /// - Parameters:
    ///   - date: Cutoff date - measurements before this date will be deleted
    ///   - confirmation: Optional confirmation callback before proceeding
    /// - Throws: LocalDataError if deletion fails
    func deleteMeasurements(before date: Date, confirmation: (() async -> Bool)? = nil) async throws {
        _isDeleting.wrappedValue = true
        _deleteProgress.wrappedValue = 0.0
        _currentOperation.wrappedValue = "Preparing to delete old measurements"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        // Request confirmation if callback provided
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                logger.log("Deletion cancelled by user")
                throw LocalDataError.operationCancelled
            }
        }

        do {
            _currentOperation.wrappedValue = "Finding measurements before \(date)"
            _deleteProgress.wrappedValue = 0.1

            let descriptor = FetchDescriptor<StressMeasurement>(
                predicate: #Predicate<StressMeasurement> { $0.timestamp < date }
            )
            let oldMeasurements = try modelContext.fetch(descriptor)

            guard !oldMeasurements.isEmpty else {
                logger.log("No measurements found before \(date)")
                _deleteProgress.wrappedValue = 1.0
                return
            }

            _currentOperation.wrappedValue = "Deleting \(oldMeasurements.count) measurements"
            logger.log("Deleting \(oldMeasurements.count) measurements from before \(date)")

            let total = Double(oldMeasurements.count)
            for (index, measurement) in oldMeasurements.enumerated() {
                modelContext.delete(measurement)

                let progress = Double(index + 1) / total
                if progress > _deleteProgress.wrappedValue + 0.1 || index == oldMeasurements.count - 1 {
                    _deleteProgress.wrappedValue = progress
                }
            }

            _currentOperation.wrappedValue = "Saving changes"
            _deleteProgress.wrappedValue = 0.9
            try modelContext.save()

            _deleteProgress.wrappedValue = 1.0
            logger.log("Successfully deleted \(oldMeasurements.count) measurements")

        } catch {
            logger.log("Failed to delete measurements before \(date): \(error.localizedDescription)")
            throw LocalDataError.deletionFailed(underlying: error)
        }
    }

    /// Delete measurements within a specific date range
    /// - Parameters:
    ///   - range: ClosedRange of dates defining the deletion window
    ///   - confirmation: Optional confirmation callback before proceeding
    /// - Throws: LocalDataError if deletion fails
    func deleteMeasurements(in range: ClosedRange<Date>, confirmation: (() async -> Bool)? = nil) async throws {
        _isDeleting.wrappedValue = true
        _deleteProgress.wrappedValue = 0.0
        _currentOperation.wrappedValue = "Preparing to delete measurements in range"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        // Request confirmation if callback provided
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                logger.log("Deletion cancelled by user")
                throw LocalDataError.operationCancelled
            }
        }

        do {
            _currentOperation.wrappedValue = "Finding measurements in date range"
            _deleteProgress.wrappedValue = 0.1

            let descriptor = FetchDescriptor<StressMeasurement>(
                predicate: #Predicate<StressMeasurement> { measurement in
                    measurement.timestamp >= range.lowerBound && measurement.timestamp <= range.upperBound
                }
            )
            let rangeMeasurements = try modelContext.fetch(descriptor)

            guard !rangeMeasurements.isEmpty else {
                logger.log("No measurements found in range \(range.lowerBound) to \(range.upperBound)")
                _deleteProgress.wrappedValue = 1.0
                return
            }

            _currentOperation.wrappedValue = "Deleting \(rangeMeasurements.count) measurements"
            logger.log("Deleting \(rangeMeasurements.count) measurements in range")

            let total = Double(rangeMeasurements.count)
            for (index, measurement) in rangeMeasurements.enumerated() {
                modelContext.delete(measurement)

                let progress = Double(index + 1) / total
                if progress > _deleteProgress.wrappedValue + 0.1 || index == rangeMeasurements.count - 1 {
                    _deleteProgress.wrappedValue = progress
                }
            }

            _currentOperation.wrappedValue = "Saving changes"
            _deleteProgress.wrappedValue = 0.9
            try modelContext.save()

            _deleteProgress.wrappedValue = 1.0
            logger.log("Successfully deleted \(rangeMeasurements.count) measurements")

        } catch {
            logger.log("Failed to delete measurements in range: \(error.localizedDescription)")
            throw LocalDataError.deletionFailed(underlying: error)
        }
    }

    // MARK: - Batch Operations

    /// Delete a specific batch of measurements
    /// - Parameter measurements: Array of measurements to delete
    /// - Throws: LocalDataError if deletion fails
    func deleteBatch(_ measurements: [StressMeasurement]) async throws {
        guard !measurements.isEmpty else { return }

        _isDeleting.wrappedValue = true
        _currentOperation.wrappedValue = "Deleting batch of \(measurements.count) measurements"

        defer {
            _isDeleting.wrappedValue = false
            _currentOperation.wrappedValue = nil
        }

        do {
            for measurement in measurements {
                modelContext.delete(measurement)
            }
            try modelContext.save()

            logger.log("Successfully deleted batch of \(measurements.count) measurements")

        } catch {
            logger.log("Failed to delete batch: \(error.localizedDescription)")
            throw LocalDataError.deletionFailed(underlying: error)
        }
    }

    // MARK: - Statistics

    /// Get count of measurements that would be deleted before a given date
    /// - Parameter date: Cutoff date
    /// - Returns: Count of measurements before the date
    func countMeasurements(before date: Date) -> Int {
        do {
            let descriptor = FetchDescriptor<StressMeasurement>(
                predicate: #Predicate<StressMeasurement> { $0.timestamp < date }
            )
            return try modelContext.fetchCount(descriptor)
        } catch {
            logger.log("Failed to count measurements: \(error.localizedDescription)")
            return 0
        }
    }

    /// Get count of measurements in a date range
    /// - Parameter range: Date range to query
    /// - Returns: Count of measurements in the range
    func countMeasurements(in range: ClosedRange<Date>) -> Int {
        do {
            let descriptor = FetchDescriptor<StressMeasurement>(
                predicate: #Predicate<StressMeasurement> { measurement in
                    measurement.timestamp >= range.lowerBound && measurement.timestamp <= range.upperBound
                }
            )
            return try modelContext.fetchCount(descriptor)
        } catch {
            logger.log("Failed to count measurements: \(error.localizedDescription)")
            return 0
        }
    }

    /// Get total count of all measurements
    /// - Returns: Total count
    func totalCount() -> Int {
        do {
            let descriptor = FetchDescriptor<StressMeasurement>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            logger.log("Failed to count measurements: \(error.localizedDescription)")
            return 0
        }
    }
}

// MARK: - Local Data Error

enum LocalDataError: Error {
    case deletionFailed(underlying: Error)
    case operationCancelled
    case unauthorizedAccess
    case contextNotFound

    var localizedDescription: String {
        switch self {
        case .deletionFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .operationCancelled:
            return "Operation was cancelled"
        case .unauthorizedAccess:
            return "Unauthorized access to data"
        case .contextNotFound:
            return "Data context not found"
        }
    }
}

