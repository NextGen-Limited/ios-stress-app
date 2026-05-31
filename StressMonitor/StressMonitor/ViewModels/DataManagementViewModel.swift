import Foundation
import SwiftData
import Observation
import UniformTypeIdentifiers

@preconcurrency import SwiftData

// MARK: - Data Management View Model
/// Observable view model for data management UI operations
@MainActor
@Observable
public final class DataManagementViewModel: Sendable {

    // MARK: - Export State

    public private(set) var isExporting = false
    public private(set) var exportProgress: Double = 0.0
    public private(set) var exportOperation: String?
    public private(set) var exportedFileURL: URL?

    // MARK: - Delete State

    public private(set) var isDeleting = false
    public private(set) var deleteProgress: Double = 0.0
    public private(set) var deleteOperation: String?

    // MARK: - Error State

    public private(set) var errorMessage: String?
    public private(set) var errorTitle: String?

    // MARK: - Success State

    public private(set) var showSuccessAlert = false
    public private(set) var successMessage: String?

    // MARK: - Confirmation State

    public private(set) var showDeleteConfirmation = false
    public private(set) var pendingDeleteOperation: DeleteOperation?

    // MARK: - Data Statistics

    public private(set) var totalMeasurementCount = 0
    public private(set) var oldestMeasurementDate: Date?
    public private(set) var newestMeasurementDate: Date?

    // MARK: - Dependencies

    private let dataManagementService: DataManagementService
    private let dataDeleterService: DataDeleterService
    private let repository: StressRepositoryProtocol
    private nonisolated let logger: Logger

    // MARK: - Completion Callbacks

    var onExportComplete: ((URL) -> Void)?
    var onDeleteComplete: (() -> Void)?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        cloudKitContainer: CKContainer = .default(),
        dataManagementService: DataManagementService? = nil,
        dataDeleterService: DataDeleterService? = nil,
        repository: StressRepositoryProtocol? = nil,
        logger: Logger = .default
    ) {
        self.repository = repository ?? StressRepository(modelContext: modelContext)
        self.logger = logger

        // Initialize services or create defaults
        if let service = dataManagementService {
            self.dataManagementService = service
        } else {
            self.dataManagementService = DataManagementService(
                repository: self.repository
            )
        }

        if let deleter = dataDeleterService {
            self.dataDeleterService = deleter
        } else {
            self.dataDeleterService = DataDeleterService(
                modelContext: modelContext,
                cloudKitContainer: cloudKitContainer,
                repository: self.repository
            )
        }
    }

    // MARK: - Load Data Statistics

    /// Load statistics about stored measurements
    public func loadStatistics() async {
        do {
            let measurements = try await repository.fetchAll()

            await MainActor.run {
                totalMeasurementCount = measurements.count

                if let oldest = measurements.last?.timestamp {
                    oldestMeasurementDate = oldest
                }

                if let newest = measurements.first?.timestamp {
                    newestMeasurementDate = newest
                }
            }

            logger.log("Loaded statistics: \(measurements.count) measurements")

        } catch {
            logger.log("Failed to load statistics: \(error.localizedDescription)")
        }
    }

    // MARK: - Export Operations

    /// Export measurements to CSV format
    /// - Parameters:
    ///   - startDate: Start date for export range
    ///   - endDate: End date for export range
    public func exportToCSV(startDate: Date? = nil, endDate: Date? = nil) async {
        isExporting = true
        exportProgress = 0.0
        exportOperation = "Preparing CSV export"
        errorMessage = nil
        exportedFileURL = nil

        defer {
            isExporting = false
        }

        do {
            let measurements = try await fetchMeasurements(forStart: startDate, end: endDate)

            guard !measurements.isEmpty else {
                showError("No Data", "No measurements found in the selected date range.")
                return
            }

            exportOperation = "Generating CSV file"
            exportProgress = 0.2

            let fileURL = try await dataManagementService.exportToCSV(measurements: measurements)

            exportProgress = 1.0
            exportedFileURL = fileURL
            exportOperation = nil

            showSuccess("Successfully exported \(measurements.count) measurements to CSV")
            onExportComplete?(fileURL)

            logger.log("CSV export completed: \(fileURL.path)")

        } catch let error as ExportError {
            showError("Export Failed", error.localizedDescription)
            logger.log("CSV export failed: \(error.localizedDescription)")
        } catch {
            showError("Export Failed", error.localizedDescription)
            logger.log("CSV export failed: \(error.localizedDescription)")
        }
    }

    /// Export measurements to JSON format
    /// - Parameters:
    ///   - startDate: Start date for export range
    ///   - endDate: End date for export range
    public func exportToJSON(startDate: Date? = nil, endDate: Date? = nil) async {
        isExporting = true
        exportProgress = 0.0
        exportOperation = "Preparing JSON export"
        errorMessage = nil
        exportedFileURL = nil

        defer {
            isExporting = false
        }

        do {
            let measurements = try await fetchMeasurements(forStart: startDate, end: endDate)

            guard !measurements.isEmpty else {
                showError("No Data", "No measurements found in the selected date range.")
                return
            }

            exportOperation = "Fetching baseline data"
            exportProgress = 0.2

            let baseline = try await repository.getBaseline()

            exportOperation = "Generating JSON file"
            exportProgress = 0.4

            let fileURL = try await dataManagementService.exportToJSON(
                measurements: measurements,
                baseline: baseline
            )

            exportProgress = 1.0
            exportedFileURL = fileURL
            exportOperation = nil

            showSuccess("Successfully exported \(measurements.count) measurements to JSON")
            onExportComplete?(fileURL)

            logger.log("JSON export completed: \(fileURL.path)")

        } catch let error as ExportError {
            showError("Export Failed", error.localizedDescription)
            logger.log("JSON export failed: \(error.localizedDescription)")
        } catch {
            showError("Export Failed", error.localizedDescription)
            logger.log("JSON export failed: \(error.localizedDescription)")
        }
    }

    /// Generate a stress report for a date range
    /// - Parameters:
    ///   - startDate: Report start date
    ///   - endDate: Report end date
    public func generateReport(startDate: Date, endDate: Date) async {
        isExporting = true
        exportProgress = 0.0
        exportOperation = "Generating stress report"
        errorMessage = nil
        exportedFileURL = nil

        defer {
            isExporting = false
        }

        do {
            exportOperation = "Collecting data for report"
            exportProgress = 0.2

            let fileURL = try await dataManagementService.generateReport(
                startDate: startDate,
                endDate: endDate
            )

            exportProgress = 1.0
            exportedFileURL = fileURL
            exportOperation = nil

            showSuccess("Successfully generated stress report")
            onExportComplete?(fileURL)

            logger.log("Report generation completed: \(fileURL.path)")

        } catch let error as ExportError {
            showError("Report Failed", error.localizedDescription)
            logger.log("Report generation failed: \(error.localizedDescription)")
        } catch {
            showError("Report Failed", error.localizedDescription)
            logger.log("Report generation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Operations

    /// Show confirmation dialog for delete all operation
    public func confirmDeleteAll() {
        pendingDeleteOperation = .deleteAll
        showDeleteConfirmation = true
    }

    /// Show confirmation dialog for delete before date operation
    /// - Parameter date: Cutoff date
    public func confirmDeleteBefore(date: Date) {
        pendingDeleteOperation = .deleteBefore(date)
        showDeleteConfirmation = true
    }

    /// Show confirmation dialog for delete in range operation
    /// - Parameter range: Date range
    public func confirmDeleteInRange(range: ClosedRange<Date>) {
        pendingDeleteOperation = .deleteInRange(range)
        showDeleteConfirmation = true
    }

    /// Show confirmation dialog for CloudKit reset operation
    public func confirmCloudKitReset() {
        pendingDeleteOperation = .resetCloudKit
        showDeleteConfirmation = true
    }

    /// Show confirmation dialog for factory reset operation
    public func confirmFactoryReset() {
        pendingDeleteOperation = .factoryReset
        showDeleteConfirmation = true
    }

    /// Execute the pending delete operation
    public func executePendingDelete() async {
        guard let operation = pendingDeleteOperation else {
            logger.log("No pending delete operation")
            return
        }

        showDeleteConfirmation = false
        await executeDelete(operation)
        pendingDeleteOperation = nil
    }

    /// Cancel the pending delete operation
    public func cancelPendingDelete() {
        showDeleteConfirmation = false
        pendingDeleteOperation = nil
    }

    /// Execute a specific delete operation
    private func executeDelete(_ operation: DeleteOperation) async {
        isDeleting = true
        deleteProgress = 0.0
        errorMessage = nil

        defer {
            isDeleting = false
        }

        do {
            switch operation {
            case .deleteAll:
                deleteOperation = "Deleting all measurements"
                try await dataDeleterService.deleteAllMeasurements()
                showSuccess("All measurements have been deleted")

            case .deleteBefore(let date):
                deleteOperation = "Deleting measurements before \(date)"
                try await dataDeleterService.deleteMeasurements(before: date)
                let count = await dataDeleterService.getTotalCount()
                showSuccess("Old measurements have been deleted. \(count) measurements remaining.")

            case .deleteInRange(let range):
                deleteOperation = "Deleting measurements in range"
                try await dataDeleterService.deleteMeasurements(in: range)
                showSuccess("Measurements in selected range have been deleted")

            case .resetCloudKit:
                deleteOperation = "Resetting CloudKit data"
                try await dataDeleterService.resetCloudKitData()
                showSuccess("CloudKit data has been reset")

            case .factoryReset:
                deleteOperation = "Performing factory reset"
                try await dataDeleterService.performFactoryReset()
                showSuccess("Factory reset complete. All data has been cleared.")
            }

            deleteProgress = 1.0
            deleteOperation = nil

            // Refresh statistics
            await loadStatistics()

            onDeleteComplete?()

            logger.log("Delete operation completed: \(operation)")

        } catch let error as DeletionError {
            showError("Delete Failed", error.localizedDescription)
            logger.log("Delete operation failed: \(error.localizedDescription)")
        } catch let error as CloudKitResetError {
            showError("Delete Failed", error.localizedDescription)
            logger.log("Delete operation failed: \(error.localizedDescription)")
        } catch {
            showError("Delete Failed", error.localizedDescription)
            logger.log("Delete operation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Fetch measurements within optional date range
    private func fetchMeasurements(forStart startDate: Date?, end endDate: Date?) async throws -> [StressMeasurement] {
        if let start = startDate, let end = endDate {
            return try await repository.fetchMeasurements(from: start, to: end)
        } else if let start = startDate {
            return try await repository.fetchMeasurements(from: start, to: Date())
        } else if let end = endDate {
            return try await repository.fetchAll().filter { $0.timestamp <= end }
        } else {
            return try await repository.fetchAll()
        }
    }

    /// Show error alert
    private func showError(_ title: String, _ message: String) {
        errorTitle = title
        errorMessage = message
    }

    /// Show success alert
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessAlert = true
    }

    /// Clear error state
    public func clearError() {
        errorMessage = nil
        errorTitle = nil
    }

    /// Clear success state
    public func clearSuccess() {
        successMessage = nil
        showSuccessAlert = false
    }
}

// MARK: - Delete Operation

public enum DeleteOperation: Equatable, Sendable {
    case deleteAll
    case deleteBefore(Date)
    case deleteInRange(ClosedRange<Date>)
    case resetCloudKit
    case factoryReset

    public static func == (lhs: DeleteOperation, rhs: DeleteOperation) -> Bool {
        switch (lhs, rhs) {
        case (.deleteAll, .deleteAll):
            return true
        case (.deleteBefore(let lDate), .deleteBefore(let rDate)):
            return lDate == rDate
        case (.deleteInRange(let lRange), .deleteInRange(let rRange)):
            return lRange.lowerBound == rRange.lowerBound && lRange.upperBound == rRange.upperBound
        case (.resetCloudKit, .resetCloudKit):
            return true
        case (.factoryReset, .factoryReset):
            return true
        default:
            return false
        }
    }
}

// MARK: - Logger

struct Logger {
    static let `default` = Logger()

    func log(_ message: String) {
        #if DEBUG
        print("[DataManagementViewModel] \(message)")
        #endif
        os_log("%{public}@", log: .default, type: .info, message)
    }
}

// MARK: - Imports

import CloudKit
import os
