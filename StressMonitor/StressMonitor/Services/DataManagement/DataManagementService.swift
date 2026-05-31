import Foundation
import UIKit
import SwiftData
import Observation
import CloudKit

/// Main service for data export and deletion operations
@MainActor
@Observable
public final class DataManagementService: DataExporter, DataDeleter {

    // MARK: - Properties

    public var isExporting: Bool = false
    public var exportProgress: Double = 0.0
    public var exportError: Error?

    private let repository: StressRepositoryProtocol
    private let cloudKitManager: CloudKitManager?
    private let fileManager: FileManager
    private let csvGenerator: CSVGenerator
    private let jsonGenerator: JSONGenerator

    private var exportTask: Task<URL, Error>?

    // MARK: - Initialization

    init(
        repository: StressRepositoryProtocol,
        cloudKitManager: CloudKitManager? = nil,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.cloudKitManager = cloudKitManager
        self.fileManager = fileManager
        self.csvGenerator = CSVGenerator()
        self.jsonGenerator = JSONGenerator()
    }

    // MARK: - DataExporter Protocol

    /// Export measurements to CSV format
    /// - Parameter measurements: Array of measurements to export
    /// - Returns: URL to the exported CSV file
    /// - Throws: ExportError if export fails
    public func exportToCSV(measurements: [StressMeasurement]) async throws -> URL {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        isExporting = true
        exportProgress = 0.0
        exportError = nil

        defer {
            isExporting = false
            exportTask = nil
        }

        exportTask = Task<URL, Error> {
            do {
                // Generate CSV content
                exportProgress = 0.2
                let csvContent = csvGenerator.generate(from: measurements)

                // Create export metadata
                exportProgress = 0.4
                let metadata = createMetadata(from: measurements, format: .csv)

                // Add metadata as comments
                let csvWithMetadata = csvGenerator.generateWithMetadata(
                    from: measurements,
                    metadata: metadata
                )

                // Write to temp file
                exportProgress = 0.6
                let fileURL = try createTempFile(
                    fileName: "stress_export_\(metadata.exportDate.timeIntervalSince1970).csv",
                    content: csvWithMetadata
                )

                exportProgress = 1.0
                return fileURL
            } catch {
                exportError = error
                throw error
            }
        }

        guard let task = exportTask else {
            throw ExportError.fileWriteFailed(NSError())
        }

        let result = try await task.value
        guard let fileURL = result as? URL else {
            throw ExportError.encodingFailed
        }
        return fileURL
    }

    /// Export measurements to JSON format
    /// - Parameters:
    ///   - measurements: Array of measurements to export
    ///   - baseline: Personal baseline data to include
    /// - Returns: URL to the exported JSON file
    /// - Throws: ExportError if export fails
    func exportToJSON(
        measurements: [StressMeasurement],
        baseline: PersonalBaseline
    ) async throws -> URL {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        isExporting = true
        exportProgress = 0.0
        exportError = nil

        defer {
            isExporting = false
            exportTask = nil
        }

        exportTask = Task<URL, Error> {
            do {
                // Create export metadata
                exportProgress = 0.2
                let metadata = createMetadata(from: measurements, format: .json)

                // Validate data
                exportProgress = 0.3
                _ = try jsonGenerator.validate(
                    measurements: measurements,
                    baseline: baseline,
                    metadata: metadata
                )

                // Generate JSON content
                exportProgress = 0.5
                let jsonContent = try jsonGenerator.generate(
                    from: measurements,
                    baseline: baseline,
                    metadata: metadata
                )

                // Write to temp file
                exportProgress = 0.8
                let fileURL = try createTempFile(
                    fileName: "stress_export_\(metadata.exportDate.timeIntervalSince1970).json",
                    content: jsonContent
                )

                exportProgress = 1.0
                return fileURL
            } catch {
                exportError = error
                throw error
            }
        }

        guard let task = exportTask else {
            throw ExportError.fileWriteFailed(NSError())
        }

        let result = try await task.value
        guard let fileURL = result as? URL else {
            throw ExportError.encodingFailed
        }
        return fileURL
    }

    /// Generate a report for a date range
    /// - Parameters:
    ///   - startDate: Start date of the report
    ///   - endDate: End date of the report
    /// - Returns: URL to the generated report file
    /// - Throws: ExportError if report generation fails
    public func generateReport(startDate: Date, endDate: Date) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        exportError = nil

        defer {
            isExporting = false
            exportTask = nil
        }

        exportTask = Task<URL, Error> {
            do {
                // Fetch measurements for date range
                exportProgress = 0.2
                let measurements = try await repository.fetchMeasurements(from: startDate, to: endDate)

                guard !measurements.isEmpty else {
                    throw ExportError.noData
                }

                // Get baseline
                exportProgress = 0.4
                let baseline = try await repository.getBaseline()

                // Generate JSON report
                exportProgress = 0.6
                let metadata = ExportMetadata(
                    exportDate: Date(),
                    deviceName: UIDevice.current.name,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    measurementCount: measurements.count,
                    startDate: startDate,
                    endDate: endDate,
                    format: .json
                )

                let jsonContent = try jsonGenerator.generate(
                    from: measurements,
                    baseline: baseline,
                    metadata: metadata
                )

                // Write to temp file
                exportProgress = 0.8
                let fileName = "stress_report_\(startDate.timeIntervalSince1970)_\(endDate.timeIntervalSince1970).json"
                let fileURL = try createTempFile(fileName: fileName, content: jsonContent)

                exportProgress = 1.0
                return fileURL
            } catch {
                exportError = error
                throw error
            }
        }

        guard let task = exportTask else {
            throw ExportError.fileWriteFailed(NSError())
        }

        let result = try await task.value
        guard let fileURL = result as? URL else {
            throw ExportError.encodingFailed
        }
        return fileURL
    }

    // MARK: - Helper Methods

    /// Create export metadata from measurements
    /// - Parameters:
    ///   - measurements: Array of measurements
    ///   - format: Export format
    /// - Returns: ExportMetadata struct
    private func createMetadata(
        from measurements: [StressMeasurement],
        format: DataExportFormat
    ) -> ExportMetadata {
        let dates = measurements.map { $0.timestamp }
        let startDate = dates.min() ?? Date()
        let endDate = dates.max() ?? Date()

        return ExportMetadata(
            exportDate: Date(),
            deviceName: UIDevice.current.name,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            measurementCount: measurements.count,
            startDate: startDate,
            endDate: endDate,
            format: format
        )
    }

    /// Create a temporary file with content
    /// - Parameters:
    ///   - fileName: Name of the file to create
    ///   - content: String content to write
    /// - Returns: URL to the created file
    /// - Throws: ExportError if file creation fails
    private func createTempFile(fileName: String, content: String) throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ExportError.fileWriteFailed(error)
        }
    }

    /// Clean up temporary export files
    /// - Parameter olderThan: Delete files older than this date
    public func cleanupTempFiles(olderThan: Date) throws {
        let tempDir = fileManager.temporaryDirectory
        let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)

        for file in files {
            if file.pathExtension == "csv" || file.pathExtension == "json" {
                let attributes = try file.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = attributes.contentModificationDate, modDate < olderThan {
                    try fileManager.removeItem(at: file)
                }
            }
        }
    }

    /// Cancel ongoing export operation
    public func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        isExporting = false
        exportProgress = 0.0
    }

    /// Get estimated export file size for measurements
    /// - Parameters:
    ///   - measurements: Array of measurements
    ///   - format: Export format
    /// - Returns: Estimated file size in bytes
    public func estimateExportSize(
        for measurements: [StressMeasurement],
        format: DataExportFormat
    ) -> Int {
        // Rough estimation based on measurement count
        let baseSize = 500 // Metadata overhead
        let perItemSize = format == .json ? 300 : 150
        return baseSize + (measurements.count * perItemSize)
    }

    // MARK: - DataDeleter Protocol (with confirmation)

    /// Delete all measurements from local storage
    /// - Parameter confirmation: Optional confirmation callback
    /// - Throws: DeletionError if deletion fails
    public func deleteAllMeasurements(confirmation: (() async -> Bool)?) async throws {
        // If confirmation provided, check it first
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                throw DeletionError.operationCancelled
            }
        }

        do {
            try await repository.deleteAllMeasurements()
        } catch {
            throw DeletionError.repositoryError(error)
        }
    }

    /// Delete measurements older than a specific date
    /// - Parameters:
    ///   - date: Cutoff date - measurements before this will be deleted
    ///   - confirmation: Optional confirmation callback
    /// - Throws: DeletionError if deletion fails
    public func deleteMeasurements(before date: Date, confirmation: (() async -> Bool)?) async throws {
        // If confirmation provided, check it first
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                throw DeletionError.operationCancelled
            }
        }

        do {
            try await repository.deleteOlderThan(date)
        } catch {
            throw DeletionError.repositoryError(error)
        }
    }

    /// Delete measurements within a date range
    /// - Parameters:
    ///   - range: Date range of measurements to delete
    ///   - confirmation: Optional confirmation callback
    /// - Throws: DeletionError if deletion fails
    public func deleteMeasurements(in range: ClosedRange<Date>, confirmation: (() async -> Bool)?) async throws {
        // If confirmation provided, check it first
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                throw DeletionError.operationCancelled
            }
        }

        // Fetch measurements in range
        let measurements = try await repository.fetchMeasurements(
            from: range.lowerBound,
            to: range.upperBound
        )

        // Delete each measurement
        for measurement in measurements {
            try await repository.delete(measurement)
        }
    }

    /// Reset CloudKit data by deleting all remote records
    /// - Parameter confirmation: Optional confirmation callback
    /// - Throws: DeletionError if reset fails
    public func resetCloudKitData(confirmation: (() async -> Bool)?) async throws {
        // If confirmation provided, check it first
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                throw DeletionError.operationCancelled
            }
        }

        guard let cloudKit = cloudKitManager else {
            throw DeletionError.cloudKitError(NSError(
                domain: "CloudKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "CloudKit manager not available"]
            ))
        }

        do {
            // Fetch all remote measurements
            let remoteMeasurements = try await cloudKit.fetchMeasurements()

            // Delete each remote measurement
            for measurement in remoteMeasurements {
                try await cloudKit.deleteMeasurement(measurement)
            }
        } catch {
            throw DeletionError.cloudKitError(error)
        }
    }

    /// Perform a complete factory reset - local data and CloudKit
    /// - Parameter confirmation: Optional confirmation callback
    /// - Warning: This action cannot be undone
    /// - Throws: DeletionError if reset fails
    public func performFactoryReset(confirmation: (() async -> Bool)?) async throws {
        // If confirmation provided, check it first
        if let confirmation = confirmation {
            let confirmed = await confirmation()
            guard confirmed else {
                throw DeletionError.operationCancelled
            }
        }

        // Delete all local measurements
        try await deleteAllMeasurements(confirmation: nil)

        // Reset CloudKit data
        try await resetCloudKitData(confirmation: nil)

        // Clear any cached baseline
        try await repository.updateBaseline(PersonalBaseline())
    }
}

// MARK: - Preview Support

#if DEBUG
extension DataManagementService {
    /// Create a sample service for preview/testing
    static func sample() -> DataManagementService {
        let context = ModelContext(try! ModelContainer(for: StressMeasurement.self))
        let repository = StressRepository(modelContext: context)
        return DataManagementService(repository: repository)
    }
}
#endif
