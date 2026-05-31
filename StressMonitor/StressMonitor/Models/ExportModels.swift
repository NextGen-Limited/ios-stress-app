import Foundation

// MARK: - Export Metadata

/// Metadata included in data exports
public struct ExportMetadata: Codable, Sendable {
    let exportDate: Date
    let deviceName: String
    let appVersion: String
    let measurementCount: Int
    let startDate: Date
    let endDate: Date
    let format: DataExportFormat

    var dateRange: ClosedRange<Date> {
        startDate...endDate
    }

    private enum CodingKeys: String, CodingKey {
        case exportDate
        case deviceName
        case appVersion
        case measurementCount
        case startDate
        case endDate
        case format
    }

    public init(
        exportDate: Date,
        deviceName: String,
        appVersion: String,
        measurementCount: Int,
        startDate: Date,
        endDate: Date,
        format: DataExportFormat
    ) {
        self.exportDate = exportDate
        self.deviceName = deviceName
        self.appVersion = appVersion
        self.measurementCount = measurementCount
        self.startDate = startDate
        self.endDate = endDate
        self.format = format
    }
}

// MARK: - Data Export Format

public enum DataExportFormat: String, Codable {
    case csv
    case json

    public var fileExtension: String {
        rawValue
    }

    public var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        }
    }
}

// MARK: - JSON Export Structure

/// Complete JSON export structure
public struct JSONExport: Codable, Sendable {
    let metadata: ExportMetadata
    let baseline: BaselineData
    let measurements: [StressSnapshot]
    let summary: ExportSummary

    init(
        metadata: ExportMetadata,
        baseline: BaselineData,
        measurements: [StressSnapshot],
        summary: ExportSummary
    ) {
        self.metadata = metadata
        self.baseline = baseline
        self.measurements = measurements
        self.summary = summary
    }
}

// MARK: - Baseline Data

/// Personal baseline data for export
public struct BaselineData: Codable, Sendable {
    public let restingHeartRate: Double
    public let baselineHRV: Double
    public let lastUpdated: Date

    internal init(from baseline: PersonalBaseline) {
        self.restingHeartRate = baseline.restingHeartRate
        self.baselineHRV = baseline.baselineHRV
        self.lastUpdated = baseline.lastUpdated
    }
}

// MARK: - Stress Snapshot

/// Single stress measurement snapshot for export
public struct StressSnapshot: Codable, Sendable {
    let timestamp: Date
    let stressLevel: Double
    let category: String
    let hrv: Double
    let heartRate: Double
    let confidence: Double
    let isSynced: Bool
    let deviceID: String

    init(from measurement: StressMeasurement) {
        self.timestamp = measurement.timestamp
        self.stressLevel = measurement.stressLevel
        self.category = measurement.category.rawValue
        self.hrv = measurement.hrv
        self.heartRate = measurement.restingHeartRate

        // Calculate average confidence
        if let confidences = measurement.confidences, !confidences.isEmpty {
            self.confidence = confidences.reduce(0, +) / Double(confidences.count)
        } else {
            self.confidence = 0.0
        }

        self.isSynced = measurement.isSynced
        self.deviceID = measurement.deviceID
    }
}

// MARK: - Export Summary

/// Statistical summary of exported data
public struct ExportSummary: Codable, Sendable {
    let totalMeasurements: Int
    let dateRange: DateRangeData
    let averages: AverageData
    let distribution: CategoryDistribution
    let peakStress: PeakStressData

    init(from measurements: [StressMeasurement]) {
        self.totalMeasurements = measurements.count

        // Calculate date range
        if let first = measurements.first?.timestamp,
           let last = measurements.last?.timestamp {
            let start = min(first, last)
            let end = max(first, last)
            self.dateRange = DateRangeData(startDate: start, endDate: end)
        } else {
            self.dateRange = DateRangeData(startDate: Date(), endDate: Date())
        }

        // Calculate averages
        let stressLevels = measurements.map { $0.stressLevel }
        let hrvs = measurements.map { $0.hrv }
        let heartRates = measurements.map { $0.restingHeartRate }

        self.averages = AverageData(
            stressLevel: stressLevels.isEmpty ? 0 : stressLevels.reduce(0, +) / Double(stressLevels.count),
            hrv: hrvs.isEmpty ? 0 : hrvs.reduce(0, +) / Double(hrvs.count),
            heartRate: heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
        )

        // Calculate category distribution
        let categories = measurements.map { $0.category }
        var distribution: [String: Int] = [:]
        for category in categories {
            distribution[category.rawValue, default: 0] += 1
        }
        self.distribution = CategoryDistribution(
            relaxed: distribution[StressCategory.relaxed.rawValue] ?? 0,
            mild: distribution[StressCategory.mild.rawValue] ?? 0,
            moderate: distribution[StressCategory.moderate.rawValue] ?? 0,
            high: distribution[StressCategory.high.rawValue] ?? 0
        )

        // Find peak stress
        if let peak = measurements.max(by: { $0.stressLevel < $1.stressLevel }) {
            self.peakStress = PeakStressData(
                level: peak.stressLevel,
                timestamp: peak.timestamp,
                category: peak.category.rawValue
            )
        } else {
            self.peakStress = PeakStressData(
                level: 0,
                timestamp: Date(),
                category: StressCategory.relaxed.rawValue
            )
        }
    }
}

// MARK: - Date Range Data

public struct DateRangeData: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let durationDays: Int

    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        let seconds = endDate.timeIntervalSince(startDate)
        self.durationDays = max(1, Int(ceil(seconds / 86400)))
    }
}

// MARK: - Average Data

public struct AverageData: Codable, Sendable {
    public let stressLevel: Double
    public let hrv: Double
    public let heartRate: Double
}

// MARK: - Category Distribution

public struct CategoryDistribution: Codable, Sendable {
    let relaxed: Int
    let mild: Int
    let moderate: Int
    let high: Int

    var total: Int {
        relaxed + mild + moderate + high
    }

    var percentages: [String: Double] {
        let total = Double(total)
        guard total > 0 else { return [:] }

        return [
            StressCategory.relaxed.rawValue: Double(relaxed) / total * 100,
            StressCategory.mild.rawValue: Double(mild) / total * 100,
            StressCategory.moderate.rawValue: Double(moderate) / total * 100,
            StressCategory.high.rawValue: Double(high) / total * 100
        ]
    }
}

// MARK: - Peak Stress Data

public struct PeakStressData: Codable, Sendable {
    public let level: Double
    public let timestamp: Date
    public let category: String
}


// MARK: - Export Errors

public enum ExportError: LocalizedError {
    case noData
    case encodingFailed
    case fileWriteFailed(Error)
    case invalidPath
    case fileAccessFailed

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "No measurements available to export."
        case .encodingFailed:
            return "Failed to encode data for export."
        case .fileWriteFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .invalidPath:
            return "Invalid file path for export."
        case .fileAccessFailed:
            return "Could not access file system"
        }
    }
}
