import Foundation

/// Generates CSV export from stress measurements
struct CSVGenerator: Sendable {

    // MARK: - Headers

    private static let headers = [
        "timestamp",
        "stress_level",
        "category",
        "hrv_ms",
        "heart_rate_bpm",
        "confidence"
    ]

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

    // MARK: - Generate CSV

    /// Generate CSV string from measurements
    /// - Parameter measurements: Array of stress measurements to export
    /// - Returns: CSV formatted string
    func generate(from measurements: [StressMeasurement]) -> String {
        guard !measurements.isEmpty else {
            return ""
        }

        var lines: [String] = []

        // Add header row
        lines.append(Self.headers.joined(separator: ","))

        // Add data rows
        for measurement in measurements {
            let row = generateRow(for: measurement)
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Generate Row

    /// Generate a single CSV row for a measurement
    /// - Parameter measurement: The stress measurement
    /// - Returns: CSV formatted row string
    private func generateRow(for measurement: StressMeasurement) -> String {
        let timestamp = Self.dateFormatter.string(from: measurement.timestamp)
        let stressLevel = String(format: "%.2f", measurement.stressLevel)
        let category = escapeCSV(measurement.category.rawValue)
        let hrv = String(format: "%.2f", measurement.hrv)
        let heartRate = String(format: "%.1f", measurement.restingHeartRate)

        // Average confidence if available, otherwise 0
        let confidence: String
        if let confidences = measurement.confidences, !confidences.isEmpty {
            let avg = confidences.reduce(0, +) / Double(confidences.count)
            confidence = String(format: "%.3f", avg)
        } else {
            confidence = "0.000"
        }

        return [
            escapeCSV(timestamp),
            stressLevel,
            category,
            hrv,
            heartRate,
            confidence
        ].joined(separator: ",")
    }

    // MARK: - CSV Escaping

    /// Escape a CSV field value if needed
    /// - Parameter value: The field value to escape
    /// - Returns: Properly escaped CSV field
    private func escapeCSV(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes and escape quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - Generate with Metadata

    /// Generate CSV with additional metadata comments
    /// - Parameters:
    ///   - measurements: Array of stress measurements to export
    ///   - metadata: Export metadata to include as comments
    /// - Returns: CSV formatted string with metadata comments
    func generateWithMetadata(
        from measurements: [StressMeasurement],
        metadata: ExportMetadata
    ) -> String {
        var csvLines: [String] = []

        // Add metadata as comments (lines starting with #)
        csvLines.append("# Stress Monitor Data Export")
        csvLines.append("# Export Date: \(Self.dateFormatter.string(from: metadata.exportDate))")
        csvLines.append("# Device: \(metadata.deviceName)")
        csvLines.append("# App Version: \(metadata.appVersion)")
        csvLines.append("# Measurements: \(metadata.measurementCount)")
        csvLines.append("# Date Range: \(Self.dateFormatter.string(from: metadata.startDate)) to \(Self.dateFormatter.string(from: metadata.endDate))")
        csvLines.append("# Format: \(metadata.format.rawValue.uppercased())")
        csvLines.append("")

        // Add the CSV data
        csvLines.append(generate(from: measurements))

        return csvLines.joined(separator: "\n")
    }
}

// MARK: - Preview Support

#if DEBUG
extension CSVGenerator {
    /// Generate sample CSV for preview/testing
    static func sample() -> String {
        let generator = CSVGenerator()
        let sampleMeasurements = StressMeasurement.samples()
        return generator.generate(from: sampleMeasurements)
    }
}

extension StressMeasurement {
    /// Create sample measurements for testing
    static func samples() -> [StressMeasurement] {
        let calendar = Calendar.current
        let now = Date()

        return (0..<5).map { index in
            let timestamp = calendar.date(byAdding: .hour, value: -index * 2, to: now) ?? now
            return StressMeasurement(
                timestamp: timestamp,
                stressLevel: Double(index * 15),
                hrv: Double(50 - index * 5),
                restingHeartRate: Double(60 + index * 3),
                confidences: [0.85, 0.90, 0.88]
            )
        }
    }
}
#endif
