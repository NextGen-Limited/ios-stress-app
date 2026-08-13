import Foundation
import CloudKit
import SwiftData
import Observation

@preconcurrency import SwiftData

// MARK: - Data Deleter Service
/// Coordinates deletion operations across local SwiftData and CloudKit storage
@MainActor
@Observable
final class DataDeleterService: DataDeleter {

    // MARK: - Published State

    public private(set) var isDeleting = false
    public private(set) var deleteProgress: Double = 0.0
    public private(set) var currentOperation: String?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let localWipeService: LocalDataWipeService
    private let cloudKitResetService: CloudKitResetServiceProtocol
    private let repository: StressRepositoryProtocol
    private nonisolated let logger: DataManagementLogger

    // MARK: - Initialization

    convenience init(
        modelContext: ModelContext,
        cloudKitContainer: CKContainer,
        repository: StressRepositoryProtocol,
        logger: DataManagementLogger
    ) {
        self.init(
            modelContext: modelContext,
            cloudKitResetService: CloudKitResetService(container: cloudKitContainer, logger: logger),
            repository: repository,
            logger: logger
        )
    }

    /// Injects a ``CloudKitResetServiceProtocol`` directly — the seam tests use to substitute
    /// a failing/cancellable fake instead of a real CKContainer.
    init(
        modelContext: ModelContext,
        cloudKitResetService: CloudKitResetServiceProtocol,
        repository: StressRepositoryProtocol,
        logger: DataManagementLogger
    ) {
        self.modelContext = modelContext
        self.localWipeService = LocalDataWipeService(modelContext: modelContext, logger: logger)
        self.cloudKitResetService = cloudKitResetService
        self.repository = repository
        self.logger = logger
    }

    // MARK: - DataDeleter Protocol

    /// Delete all measurements from both local and CloudKit storage
    /// - Parameter confirmation: Optional confirmation callback
    public func deleteAllMeasurements(confirmation: (() async -> Bool)? = nil) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing to delete all measurements"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            // Request confirmation if provided
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("Delete all cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Last safe checkpoint before the operation becomes irreversible —
            // once CloudKit deletion starts, local deletion always follows so the
            // two stores never diverge (see CR-01: cancelling mid-flight can't
            // remove data from CloudKit only).
            try Task.checkCancellation()

            // Phase 1: Delete from CloudKit (0% - 40%)
            currentOperation = "Deleting from CloudKit"
            deleteProgress = 0.1

            try await cloudKitResetService.deleteRecords(
                ofType: .stressMeasurement,
                expectedProgress: 0.1...0.4
            )

            // Phase 2: Delete from local storage (40% - 100%)
            currentOperation = "Deleting from local storage"
            deleteProgress = 0.5

            try await localWipeService.deleteAllMeasurements()

            // Clear cached baseline
            try await repository.updateBaseline(PersonalBaseline())

            Self.clearCredentialsAndSharedCaches()

            deleteProgress = 1.0
            currentOperation = "Deletion complete"
            logger.log("Successfully deleted all measurements from both storage locations")

        } catch let error as DeletionError {
            logger.log("Delete all failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("Delete all failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch is CancellationError {
            logger.log("Delete all cancelled")
            throw DeletionError.operationCancelled
        } catch {
            logger.log("Delete all failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.repositoryError(error)
        }
    }

    /// Delete measurements older than a specified date from both storage locations
    /// - Parameters:
    ///   - date: Cutoff date
    ///   - confirmation: Optional confirmation callback
    public func deleteMeasurements(before date: Date, confirmation: (() async -> Bool)? = nil) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing to delete measurements before \(date)"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            // Request confirmation if provided
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("Delete before cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Last safe checkpoint before the operation becomes irreversible —
            // once CloudKit deletion starts, local deletion always follows so the
            // two stores never diverge (see CR-01).
            try Task.checkCancellation()

            // Phase 1: Delete from CloudKit
            currentOperation = "Deleting from CloudKit"
            deleteProgress = 0.1

            try await cloudKitResetService.deleteRecords(
                ofType: .stressMeasurement,
                before: date
            )

            // Phase 2: Delete from local storage
            currentOperation = "Deleting from local storage"
            deleteProgress = 0.6

            try await localWipeService.deleteMeasurements(before: date)

            // Recalculate baseline if needed
            try await repository.updateBaseline(PersonalBaseline())

            deleteProgress = 1.0
            currentOperation = "Deletion complete"
            logger.log("Successfully deleted measurements before \(date)")

        } catch let error as DeletionError {
            logger.log("Delete before failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("Delete before failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch is CancellationError {
            logger.log("Delete before cancelled")
            throw DeletionError.operationCancelled
        } catch {
            logger.log("Delete before failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.repositoryError(error)
        }
    }

    /// Delete measurements within a date range from both storage locations
    /// - Parameters:
    ///   - range: Date range for deletion
    ///   - confirmation: Optional confirmation callback
    public func deleteMeasurements(in range: ClosedRange<Date>, confirmation: (() async -> Bool)? = nil) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing to delete measurements in range"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            // Request confirmation if provided
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("Delete in range cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Last safe checkpoint before the operation becomes irreversible —
            // once CloudKit deletion starts, local deletion always follows so the
            // two stores never diverge (see CR-01).
            try Task.checkCancellation()

            // Phase 1: Delete from CloudKit
            currentOperation = "Deleting from CloudKit"
            deleteProgress = 0.1

            try await cloudKitResetService.deleteRecords(
                ofType: .stressMeasurement,
                in: range
            )

            // Phase 2: Delete from local storage
            currentOperation = "Deleting from local storage"
            deleteProgress = 0.6

            try await localWipeService.deleteMeasurements(in: range)

            // Recalculate baseline if needed
            try await repository.updateBaseline(PersonalBaseline())

            deleteProgress = 1.0
            currentOperation = "Deletion complete"
            logger.log("Successfully deleted measurements in range \(range)")

        } catch let error as DeletionError {
            logger.log("Delete in range failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("Delete in range failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch is CancellationError {
            logger.log("Delete in range cancelled")
            throw DeletionError.operationCancelled
        } catch {
            logger.log("Delete in range failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.repositoryError(error)
        }
    }

    /// Delete measurements within a date range, honoring which storage locations to affect.
    /// - Parameters:
    ///   - range: Date range for deletion
    ///   - includeLocal: Whether to delete from local SwiftData storage
    ///   - includeCloud: Whether to delete from CloudKit
    ///   - confirmation: Optional confirmation callback
    public func deleteMeasurements(
        in range: ClosedRange<Date>,
        includeLocal: Bool,
        includeCloud: Bool,
        confirmation: (() async -> Bool)? = nil
    ) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing to delete measurements in range"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("Delete in range (scoped) cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Last safe checkpoint before the operation becomes irreversible —
            // once CloudKit deletion starts, local deletion always follows so the
            // two stores never diverge (see CR-01).
            try Task.checkCancellation()

            if includeCloud {
                currentOperation = "Deleting from CloudKit"
                deleteProgress = 0.1

                try await cloudKitResetService.deleteRecords(
                    ofType: .stressMeasurement,
                    in: range
                )
            }

            if includeLocal {
                currentOperation = "Deleting from local storage"
                deleteProgress = 0.6

                try await localWipeService.deleteMeasurements(in: range)

                // Baseline is scoped to local data — only reset it when local storage is affected.
                try await repository.updateBaseline(PersonalBaseline())
            }

            deleteProgress = 1.0
            currentOperation = "Deletion complete"
            logger.log("Successfully deleted measurements in range \(range) (local: \(includeLocal), cloud: \(includeCloud))")

        } catch let error as DeletionError {
            logger.log("Delete in range (scoped) failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("Delete in range (scoped) failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch is CancellationError {
            logger.log("Delete in range (scoped) cancelled")
            throw DeletionError.operationCancelled
        } catch {
            logger.log("Delete in range (scoped) failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.repositoryError(error)
        }
    }

    /// Reset all CloudKit data (measurements, baseline, metadata)
    /// - Parameter confirmation: Optional confirmation callback
    public func resetCloudKitData(confirmation: (() async -> Bool)? = nil) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing CloudKit reset"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            // Request confirmation if provided
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("CloudKit reset cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Last safe checkpoint before the operation becomes irreversible —
            // a cancellation after this point must be classified as
            // DeletionError.operationCancelled, not a misleading cloudKitError/repositoryError.
            try Task.checkCancellation()

            // Delete all CloudKit records
            try await cloudKitResetService.deleteAllRecords(
                confirmation: nil, // Already confirmed above
                includeBaseline: true
            )

            deleteProgress = 1.0
            currentOperation = "CloudKit reset complete"
            logger.log("Successfully reset all CloudKit data")

        } catch let error as DeletionError {
            logger.log("CloudKit reset failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("CloudKit reset failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch is CancellationError {
            logger.log("CloudKit reset cancelled")
            throw DeletionError.operationCancelled
        } catch {
            logger.log("CloudKit reset failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        }
    }

    /// Perform a complete factory reset - clears all data from both storage locations
    /// - Parameter confirmation: Optional confirmation callback
    public func performFactoryReset(confirmation: (() async -> Bool)? = nil) async throws {
        isDeleting = true
        deleteProgress = 0.0
        currentOperation = "Preparing factory reset"

        defer {
            isDeleting = false
            currentOperation = nil
        }

        do {
            // Request confirmation if provided
            if let confirmation = confirmation {
                let confirmed = await confirmation()
                guard confirmed else {
                    logger.log("Factory reset cancelled by user")
                    throw DeletionError.operationCancelled
                }
            }

            // Phase 1: Reset CloudKit (0% - 50%)
            currentOperation = "Resetting CloudKit data"
            deleteProgress = 0.05

            try await cloudKitResetService.performDatabaseReset(confirmation: nil)

            // Phase 2: Reset local storage (50% - 90%)
            currentOperation = "Clearing local data"
            deleteProgress = 0.55

            try await localWipeService.deleteAllMeasurements()
            try modelContext.delete(model: CharacterUnlock.self)
            try modelContext.save()

            // Phase 3: Reset baseline (90% - 100%)
            currentOperation = "Resetting baseline"
            deleteProgress = 0.9

            try await repository.updateBaseline(PersonalBaseline())

            Self.clearCredentialsAndSharedCaches()

            deleteProgress = 1.0
            currentOperation = "Factory reset complete"
            logger.log("Successfully performed factory reset")

        } catch let error as DeletionError {
            logger.log("Factory reset failed: \(error.localizedDescription)")
            throw error
        } catch let error as CloudKitResetError {
            logger.log("Factory reset failed: \(error.localizedDescription)")
            throw DeletionError.cloudKitError(error)
        } catch {
            logger.log("Factory reset failed with unexpected error: \(error.localizedDescription)")
            throw DeletionError.repositoryError(error)
        }
    }

    // MARK: - Convenience Methods

    /// Get statistics about measurements that would be affected by deletion
    /// - Parameter date: Cutoff date
    /// - Returns: Count of measurements before the date
    func getDeletionStats(before date: Date) async -> Int {
        return await MainActor.run {
            localWipeService.countMeasurements(before: date)
        }
    }

    /// Get statistics about measurements in a date range
    /// - Parameter range: Date range
    /// - Returns: Count of measurements in the range
    func getDeletionStats(in range: ClosedRange<Date>) async -> Int {
        return await MainActor.run {
            localWipeService.countMeasurements(in: range)
        }
    }

    /// Get total count of all measurements
    /// - Returns: Total count
    func getTotalCount() async -> Int {
        return await MainActor.run {
            localWipeService.totalCount()
        }
    }

    // MARK: - Credential & Shared Cache Clearance

    /// Clears the Firebase auth session and legacy Keychain tokens, then wipes
    /// the App Group widget/complication cache. Called from both delete-all and
    /// factory-reset paths so a "deleted" user is actually signed out and the
    /// widget stops showing deleted data.
    static func clearCredentialsAndSharedCaches() {
        FirebaseAuthService.clearStoredCredentials()
        UserDefaults(suiteName: WidgetConstants.appGroupID)?
            .removePersistentDomain(forName: WidgetConstants.appGroupID)
    }
}
