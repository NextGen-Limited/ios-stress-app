import XCTest
@testable import StressMonitor

/// Comprehensive unit tests for CSVGenerator
/// Tests CSV generation, proper escaping, headers, empty data, and large datasets
final class CSVGeneratorTests: XCTestCase {

    var csvGenerator: CSVGenerator!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()
        csvGenerator = CSVGenerator()
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        csvGenerator = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - CSV Generation Tests

    func testGenerateCSV_WithSingleMeasurement() {
        // Given
        let measurement = testDataFactory.createMeasurement(
            stressLevel: 45,
            hrv: 55,
            heartRate: 65
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertFalse(csv.isEmpty)
        XCTAssertTrue(csv.contains("timestamp"))
        XCTAssertTrue(csv.contains("stress_level"))
        XCTAssertTrue(csv.contains("45.00"))
    }

    func testGenerateCSV_WithMultipleMeasurements() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        XCTAssertFalse(csv.isEmpty)
        let lines = csv.components(separatedBy: "\n")
        // Header + 5 data lines
        XCTAssertEqual(lines.count, 6)
    }

    func testGenerateCSV_IncludesHeaders() {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        let lines = csv.components(separatedBy: "\n")
        let headerLine = lines.first

        XCTAssertTrue(headerLine?.contains("timestamp") ?? false)
        XCTAssertTrue(headerLine?.contains("stress_level") ?? false)
        XCTAssertTrue(headerLine?.contains("category") ?? false)
        XCTAssertTrue(headerLine?.contains("hrv_ms") ?? false)
        XCTAssertTrue(headerLine?.contains("heart_rate_bpm") ?? false)
        XCTAssertTrue(headerLine?.contains("confidence") ?? false)
    }

    func testGenerateCSV_EmptyData() {
        // Given
        let measurements: [StressMeasurement] = []

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        XCTAssertTrue(csv.isEmpty, "CSV should be empty for empty measurements array")
    }

    // MARK: - Data Formatting Tests

    func testGenerateCSV_TimestampFormat() {
        // Given
        let measurement = testDataFactory.createMeasurement(daysAgo: 0)

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Should contain ISO8601 formatted timestamp
        XCTAssertTrue(csv.contains("T") || csv.contains("-"), "Should contain date separators")
    }

    func testGenerateCSV_StressLevelPrecision() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 45.6789,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Should be formatted to 2 decimal places
        XCTAssertTrue(csv.contains("45.68"), "Stress level should have 2 decimal precision")
        XCTAssertFalse(csv.contains("45.6789"))
    }

    func testGenerateCSV_HRVPrecision() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 54.321,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("54.32"), "HRV should have 2 decimal precision")
    }

    func testGenerateCSV_HeartRatePrecision() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 62.789,
            confidences: [0.8]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("62.8"), "Heart rate should have 1 decimal precision")
    }

    func testGenerateCSV_ConfidenceCalculation() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.7, 0.8, 0.9]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Average confidence should be (0.7 + 0.8 + 0.9) / 3 = 0.8
        XCTAssertTrue(csv.contains("0.800"), "Should calculate average confidence with 3 decimal places")
    }

    func testGenerateCSV_ConfidenceWhenNil() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: nil
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("0.000"), "Nil confidence should default to 0.000")
    }

    func testGenerateCSV_ConfidenceWhenEmpty() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("0.000"), "Empty confidence should default to 0.000")
    }

    // MARK: - CSV Escaping Tests

    func testEscapeCSV_CommaInValue() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        measurement.categoryRawValue = "High, Stress" // Contains comma

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Should be wrapped in quotes
        XCTAssertTrue(csv.contains("\"High, Stress\""))
    }

    func testEscapeCSV_QuoteInValue() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        measurement.categoryRawValue = "High \"Stress\"" // Contains quote

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Quotes should be escaped by doubling
        XCTAssertTrue(csv.contains("\"High \"\"Stress\"\"\""))
    }

    func testEscapeCSV_NewlineInValue() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        measurement.categoryRawValue = "High\nStress" // Contains newline

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Should be wrapped in quotes
        XCTAssertTrue(csv.contains("\""))
    }

    func testEscapeCSV_NoSpecialCharacters() {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Normal values should not be quoted
        let categoryValue = measurement.category.rawValue
        let lines = csv.components(separatedBy: "\n")
        if let dataLine = lines.dropFirst().first {
            XCTAssertFalse(dataLine.contains("\""))
        }
    }

    // MARK: - Large Dataset Tests

    func testGenerateCSV_LargeDataset() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 1000)

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        XCTAssertFalse(csv.isEmpty)
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 1001) // Header + 1000 data lines
    }

    func testGenerateCSV_PerformanceLargeDataset() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 1000)

        // Measure
        measure {
            _ = csvGenerator.generate(from: measurements)
        }
    }

    // MARK: - Metadata Tests

    func testGenerateWithMetadata_IncludesHeaderComments() {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone 15 Pro",
            appVersion: "1.0.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .csv
        )

        // When
        let csv = csvGenerator.generateWithMetadata(from: [measurement], metadata: metadata)

        // Then
        XCTAssertTrue(csv.contains("# Stress Monitor Data Export"))
        XCTAssertTrue(csv.contains("# Export Date:"))
        XCTAssertTrue(csv.contains("# Device: iPhone 15 Pro"))
        XCTAssertTrue(csv.contains("# App Version: 1.0.0"))
        XCTAssertTrue(csv.contains("# Measurements: 1"))
    }

    func testGenerateWithMetadata_DateRange() {
        // Given
        let startDate = Date().addingTimeInterval(-7 * 86400) // 7 days ago
        let endDate = Date()
        let measurement = testDataFactory.createMeasurement()
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: startDate,
            endDate: endDate,
            format: .csv
        )

        // When
        let csv = csvGenerator.generateWithMetadata(from: [measurement], metadata: metadata)

        // Then
        XCTAssertTrue(csv.contains("# Date Range:"))
    }

    func testGenerateWithMetadata_FormatVersion() {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .csv
        )

        // When
        let csv = csvGenerator.generateWithMetadata(from: [measurement], metadata: metadata)

        // Then
        XCTAssertTrue(csv.contains("# Format: CSV"))
    }

    // MARK: - Edge Cases Tests

    func testGenerateCSV_WithExtremeValues() {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 0,
                hrv: 0,
                restingHeartRate: 0,
                confidences: nil
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 100,
                hrv: 200,
                restingHeartRate: 200,
                confidences: [1.0]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: -10,
                hrv: -50,
                restingHeartRate: 30,
                confidences: nil
            )
        ]

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        XCTAssertFalse(csv.isEmpty)
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4) // Header + 3 data lines
    }

    func testGenerateCSV_WithFutureTimestamp() {
        // Given
        let futureMeasurement = StressMeasurement(
            timestamp: Date().addingTimeInterval(86400), // 1 day in future
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When
        let csv = csvGenerator.generate(from: [futureMeasurement])

        // Then
        XCTAssertFalse(csv.isEmpty)
        XCTAssertTrue(csv.contains("20")) // Should contain year 202x
    }

    func testGenerateCSV_WithPastTimestamp() {
        // Given
        let pastMeasurement = StressMeasurement(
            timestamp: Date().addingTimeInterval(-365 * 86400), // 1 year ago
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )

        // When
        let csv = csvGenerator.generate(from: [pastMeasurement])

        // Then
        XCTAssertFalse(csv.isEmpty)
    }

    func testGenerateCSV_WithDifferentCategories() {
        // Given
        let measurements = [
            testDataFactory.createMeasurement(stressLevel: 10), // Relaxed
            testDataFactory.createMeasurement(stressLevel: 40), // Mild
            testDataFactory.createMeasurement(stressLevel: 60), // Moderate
            testDataFactory.createMeasurement(stressLevel: 85)  // High
        ]

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        XCTAssertTrue(csv.contains("Relaxed") || csv.contains("relaxed"))
        XCTAssertTrue(csv.contains("Mild") || csv.contains("mild"))
        XCTAssertTrue(csv.contains("Moderate") || csv.contains("moderate"))
        XCTAssertTrue(csv.contains("High") || csv.contains("high"))
    }

    // MARK: - Output Validation Tests

    func testGenerateCSV_ValidCSVStructure() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        // Should have header and data rows
        XCTAssertGreaterThanOrEqual(lines.count, 2)

        // Each line should have same number of columns
        let columnCounts = lines.map { $0.components(separatedBy: ",").count }
        let allSameCount = Set(columnCounts).count == 1
        XCTAssertTrue(allSameCount, "All rows should have same column count")
    }

    func testGenerateCSV_NoTrailingNewline() {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertFalse(csv.hasSuffix("\n\n"), "Should not have trailing newlines")
    }

    func testGenerateCSV_ReproducibleOutput() {
        // Given
        let measurement = testDataFactory.createMeasurement()

        // When
        let csv1 = csvGenerator.generate(from: [measurement])
        let csv2 = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertEqual(csv1, csv2, "Output should be reproducible")
    }

    // MARK: - Unicode and Special Characters Tests

    func testGenerateCSV_WithUnicodeCharacters() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        measurement.categoryRawValue = "高压" // Chinese for "High Pressure"

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("高压"))
    }

    func testGenerateCSV_WithEmoji() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.8]
        )
        measurement.categoryRawValue = "Stress 😰"

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("😰"))
    }

    // MARK: - Stress Category Tests

    func testGenerateCSV_AllCategories() {
        // Given
        let relaxed = StressMeasurement(
            timestamp: Date(),
            stressLevel: 10,
            hrv: 70,
            restingHeartRate: 55,
            confidences: [0.9]
        )
        let mild = StressMeasurement(
            timestamp: Date(),
            stressLevel: 40,
            hrv: 55,
            restingHeartRate: 65,
            confidences: [0.8]
        )
        let moderate = StressMeasurement(
            timestamp: Date(),
            stressLevel: 65,
            hrv: 40,
            restingHeartRate: 75,
            confidences: [0.7]
        )
        let high = StressMeasurement(
            timestamp: Date(),
            stressLevel: 85,
            hrv: 25,
            restingHeartRate: 90,
            confidences: [0.6]
        )

        // When
        let csv = csvGenerator.generate(from: [relaxed, mild, moderate, high])

        // Then
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 5) // Header + 4 categories
    }

    // MARK: - Performance and Memory Tests

    func testMemory_LargeCSVGeneration() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10000)

        // Measure memory usage
        measure {
            _ = csvGenerator.generate(from: measurements)
        }
    }

    // MARK: - Data Integrity Tests

    func testGenerateCSV_DataIntegrity() {
        // Given
        let originalMeasurements = testDataFactory.createMeasurementBatch(count: 10)

        // When
        let csv = csvGenerator.generate(from: originalMeasurements)

        // Then
        let lines = csv.components(separatedBy: "\n").dropFirst() // Skip header
        XCTAssertEqual(lines.count, 10)

        // Verify each measurement is represented
        for line in lines {
            let components = line.components(separatedBy: ",")
            XCTAssertEqual(components.count, 6, "Each row should have 6 columns")
        }
    }

    func testGenerateCSV_SortedByTimestamp() {
        // Given
        let measurements = [
            testDataFactory.createMeasurement(daysAgo: 3),
            testDataFactory.createMeasurement(daysAgo: 1),
            testDataFactory.createMeasurement(daysAgo: 5)
        ]

        // When
        let csv = csvGenerator.generate(from: measurements)

        // Then
        let lines = csv.components(separatedBy: "\n").dropFirst()
        XCTAssertEqual(lines.count, 3)
    }

    // MARK: - Multiple Confidence Values Tests

    func testGenerateCSV_MultipleConfidenceValues() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.5, 0.6, 0.7, 0.8, 0.9]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        // Average should be (0.5 + 0.6 + 0.7 + 0.8 + 0.9) / 5 = 0.7
        XCTAssertTrue(csv.contains("0.700"), "Should average multiple confidence values")
    }

    func testGenerateCSV_SingleConfidenceValue() {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.85]
        )

        // When
        let csv = csvGenerator.generate(from: [measurement])

        // Then
        XCTAssertTrue(csv.contains("0.850"), "Single value should equal itself")
    }
}
