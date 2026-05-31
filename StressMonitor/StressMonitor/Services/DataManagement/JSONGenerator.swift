import Foundation

/// Generates JSON export with full structure including metadata, baseline, measurements, and summary
struct JSONGenerator: Sendable {

    // MARK: - Date Formatting

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    // MARK: - Generate JSON

    /// Generate complete JSON export string
    /// - Parameters:
    ///   - measurements: Array of stress measurements to export
    ///   - baseline: Personal baseline data
    ///   - metadata: Export metadata
    /// - Returns: JSON formatted string
    /// - Throws: ExportError if encoding fails
    func generate(
        from measurements: [StressMeasurement],
        baseline: PersonalBaseline,
        metadata: ExportMetadata
    ) throws -> String {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        // Create snapshots
        let snapshots = measurements.map { StressSnapshot(from: $0) }

        // Create summary
        let summary = ExportSummary(from: measurements)

        // Create baseline data
        let baselineData = BaselineData(from: baseline)

        // Create full export structure
        let export = JSONExport(
            metadata: metadata,
            baseline: baselineData,
            measurements: snapshots,
            summary: summary
        )

        // Encode to JSON
        do {
            let jsonData = try Self.encoder.encode(export)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ExportError.encodingFailed
            }
            return jsonString
        } catch {
            throw ExportError.encodingFailed
        }
    }

    // MARK: - Generate with Custom Sorting

    /// Generate JSON with custom field ordering for better readability
    /// - Parameters:
    ///   - measurements: Array of stress measurements to export
    ///   - baseline: Personal baseline data
    ///   - metadata: Export metadata
    /// - Returns: JSON formatted string with custom field ordering
    /// - Throws: ExportError if encoding fails
    func generateWithCustomSorting(
        from measurements: [StressMeasurement],
        baseline: PersonalBaseline,
        metadata: ExportMetadata
    ) throws -> String {
        let json = try generate(from: measurements, baseline: baseline, metadata: metadata)

        // Apply custom formatting if needed
        return formatJSONString(json)
    }

    // MARK: - Format JSON String

    /// Apply additional formatting to JSON string
    /// - Parameter jsonString: Raw JSON string
    /// - Returns: Formatted JSON string
    private func formatJSONString(_ jsonString: String) -> String {
        // Add export header comment
        let header = """
        {
          "_comment": "Stress Monitor Data Export",
          "_formatVersion": "1.0",
        """

        // Insert header after opening brace
        let formatted = jsonString.hasPrefix("{") ? header + String(jsonString.dropFirst()) : jsonString

        return formatted
    }

    // MARK: - Generate Minimal JSON

    /// Generate minimal JSON without pretty printing for smaller file size
    /// - Parameters:
    ///   - measurements: Array of stress measurements to export
    ///   - baseline: Personal baseline data
    ///   - metadata: Export metadata
    /// - Returns: Compact JSON formatted string
    /// - Throws: ExportError if encoding fails
    func generateMinimal(
        from measurements: [StressMeasurement],
        baseline: PersonalBaseline,
        metadata: ExportMetadata
    ) throws -> String {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [] // No pretty printing
            return encoder
        }()

        let snapshots = measurements.map { StressSnapshot(from: $0) }
        let summary = ExportSummary(from: measurements)
        let baselineData = BaselineData(from: baseline)

        let export = JSONExport(
            metadata: metadata,
            baseline: baselineData,
            measurements: snapshots,
            summary: summary
        )

        do {
            let jsonData = try encoder.encode(export)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ExportError.encodingFailed
            }
            return jsonString
        } catch {
            throw ExportError.encodingFailed
        }
    }

    // MARK: - Generate Measurement Array Only

    /// Generate JSON containing only measurements array
    /// - Parameter measurements: Array of stress measurements to export
    /// - Returns: JSON formatted string
    /// - Throws: ExportError if encoding fails
    func generateMeasurementsOnly(from measurements: [StressMeasurement]) throws -> String {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        let snapshots = measurements.map { StressSnapshot(from: $0) }

        do {
            let jsonData = try Self.encoder.encode(snapshots)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw ExportError.encodingFailed
            }
            return jsonString
        } catch {
            throw ExportError.encodingFailed
        }
    }

    // MARK: - Validate JSON

    /// Validate JSON structure before export
    /// - Parameters:
    ///   - measurements: Array of stress measurements
    ///   - baseline: Personal baseline data
    ///   - metadata: Export metadata
    /// - Returns: True if valid, throws error otherwise
    /// - Throws: ExportError if validation fails
    func validate(
        measurements: [StressMeasurement],
        baseline: PersonalBaseline,
        metadata: ExportMetadata
    ) throws -> Bool {
        guard !measurements.isEmpty else {
            throw ExportError.noData
        }

        // Validate date range
        guard metadata.startDate <= metadata.endDate else {
            throw ExportError.invalidPath
        }

        // Validate measurement count matches metadata
        guard metadata.measurementCount == measurements.count else {
            throw ExportError.encodingFailed
        }

        // Validate baseline values
        guard baseline.restingHeartRate > 0 && baseline.baselineHRV > 0 else {
            throw ExportError.encodingFailed
        }

        return true
    }
}

// MARK: - Preview Support

#if DEBUG
extension JSONGenerator {
    /// Generate sample JSON for preview/testing
    static func sample() throws -> String {
        let generator = JSONGenerator()
        let sampleMeasurements = StressMeasurement.samples()
        let baseline = PersonalBaseline(
            restingHeartRate: 62.0,
            baselineHRV: 48.0,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone 15 Pro",
            appVersion: "1.0.0",
            measurementCount: sampleMeasurements.count,
            startDate: sampleMeasurements.last?.timestamp ?? Date(),
            endDate: sampleMeasurements.first?.timestamp ?? Date(),
            format: .json
        )

        return try generator.generate(
            from: sampleMeasurements,
            baseline: baseline,
            metadata: metadata
        )
    }
}
#endif
