import XCTest
@testable import StressMonitor

/// Comprehensive unit tests for JSONGenerator
/// Tests JSON generation, metadata inclusion, summary calculations, baseline data, and validation
final class JSONGeneratorTests: XCTestCase {

    var jsonGenerator: JSONGenerator!
    var testDataFactory: TestDataFactory!

    override func setUp() async throws {
        try await super.setUp()
        jsonGenerator = JSONGenerator()
        testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        jsonGenerator = nil
        testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - JSON Generation Tests

    func testGenerateJSON_ValidOutput() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 62.0,
            baselineHRV: 48.0,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone 15 Pro",
            appVersion: "1.0.0",
            measurementCount: 5,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        XCTAssertTrue(json.contains("{"))
        XCTAssertTrue(json.contains("}"))
    }

    func testGenerateJSON_WithMetadata() throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "Test Device",
            appVersion: "2.0.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"metadata\""))
        XCTAssertTrue(json.contains("\"deviceName\""))
        XCTAssertTrue(json.contains("Test Device"))
        XCTAssertTrue(json.contains("\"appVersion\""))
        XCTAssertTrue(json.contains("2.0.0"))
    }

    func testGenerateJSON_WithBaselineData() throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 65.5,
            baselineHRV: 47.3,
            lastUpdated: Date().addingTimeInterval(-86400)
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"baseline\""))
        XCTAssertTrue(json.contains("\"restingHeartRate\""))
        XCTAssertTrue(json.contains("65.5"))
        XCTAssertTrue(json.contains("\"baselineHRV\""))
        XCTAssertTrue(json.contains("47.3"))
    }

    func testGenerateJSON_WithMeasurements() throws {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 45.5,
                hrv: 52.3,
                restingHeartRate: 68.0,
                confidences: [0.8, 0.9]
            ),
            StressMeasurement(
                timestamp: Date().addingTimeInterval(-3600),
                stressLevel: 67.8,
                hrv: 38.9,
                restingHeartRate: 82.0,
                confidences: [0.7]
            )
        ]
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 2,
            startDate: measurements.last!.timestamp,
            endDate: measurements.first!.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"measurements\""))
        XCTAssertTrue(json.contains("45.5"))
        XCTAssertTrue(json.contains("67.8"))
        XCTAssertTrue(json.contains("52.3"))
        XCTAssertTrue(json.contains("38.9"))
    }

    func testGenerateJSON_WithSummary() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 10)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 10,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"summary\""))
        XCTAssertTrue(json.contains("\"totalMeasurements\""))
        XCTAssertTrue(json.contains("\"averages\""))
        XCTAssertTrue(json.contains("\"distribution\""))
    }

    // MARK: - Summary Calculation Tests

    func testSummary_DateRange() throws {
        // Given
        let startDate = Date().addingTimeInterval(-7 * 86400)
        let endDate = Date()
        let measurements = [
            StressMeasurement(
                timestamp: startDate,
                stressLevel: 50,
                hrv: 50,
                restingHeartRate: 60,
                confidences: [0.8]
            ),
            StressMeasurement(
                timestamp: endDate,
                stressLevel: 55,
                hrv: 55,
                restingHeartRate: 65,
                confidences: [0.9]
            )
        ]
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 2,
            startDate: startDate,
            endDate: endDate,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"dateRange\""))
        XCTAssertTrue(json.contains("\"startDate\""))
        XCTAssertTrue(json.contains("\"endDate\""))
        XCTAssertTrue(json.contains("\"durationDays\""))
    }

    func testSummary_Averages() throws {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 40,
                hrv: 60,
                restingHeartRate: 60,
                confidences: [0.8]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 60,
                hrv: 40,
                restingHeartRate: 80,
                confidences: [0.9]
            )
        ]
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 2,
            startDate: measurements.first!.timestamp,
            endDate: measurements.first!.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        // Average stress: (40 + 60) / 2 = 50
        // Average HRV: (60 + 40) / 2 = 50
        // Average HR: (60 + 80) / 2 = 70
        XCTAssertTrue(json.contains("\"averages\""))
        XCTAssertTrue(json.contains("\"stressLevel\""))
    }

    func testSummary_CategoryDistribution() throws {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 10, // Relaxed
                hrv: 70,
                restingHeartRate: 55,
                confidences: [0.9]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 40, // Mild
                hrv: 55,
                restingHeartRate: 65,
                confidences: [0.8]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 65, // Moderate
                hrv: 40,
                restingHeartRate: 75,
                confidences: [0.7]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 85, // High
                hrv: 25,
                restingHeartRate: 90,
                confidences: [0.6]
            )
        ]
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 4,
            startDate: measurements.last!.timestamp,
            endDate: measurements.first!.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"distribution\""))
        XCTAssertTrue(json.contains("\"relaxed\""))
        XCTAssertTrue(json.contains("\"mild\""))
        XCTAssertTrue(json.contains("\"moderate\""))
        XCTAssertTrue(json.contains("\"high\""))
    }

    func testSummary_PeakStress() throws {
        // Given
        let measurements = [
            StressMeasurement(
                timestamp: Date().addingTimeInterval(-3600),
                stressLevel: 30,
                hrv: 65,
                restingHeartRate: 58,
                confidences: [0.9]
            ),
            StressMeasurement(
                timestamp: Date(),
                stressLevel: 92,
                hrv: 20,
                restingHeartRate: 95,
                confidences: [0.95]
            )
        ]
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 2,
            startDate: measurements.last!.timestamp,
            endDate: measurements.first!.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(json.contains("\"peakStress\""))
        XCTAssertTrue(json.contains("\"level\""))
        XCTAssertTrue(json.contains("\"timestamp\""))
        XCTAssertTrue(json.contains("\"category\""))
    }

    // MARK: - Validation Tests

    func testValidate_Success() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 62,
            baselineHRV: 48,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 5,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let isValid = try jsonGenerator.validate(
            measurements: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertTrue(isValid)
    }

    func testValidate_EmptyMeasurements() {
        // Given
        let measurements: [StressMeasurement] = []
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 0,
            startDate: Date(),
            endDate: Date(),
            format: .json
        )

        // When/Then
        do {
            _ = try jsonGenerator.validate(
                measurements: measurements,
                baseline: baseline,
                metadata: metadata
            )
            XCTFail("Expected ExportError.noData")
        } catch ExportError.noData {
            // Expected
        } catch {
            XCTFail("Expected ExportError.noData, got: \(error)")
        }
    }

    func testValidate_InvalidDateRange() {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: Date(), // Later than endDate
            endDate: Date().addingTimeInterval(-86400),
            format: .json
        )

        // When/Then
        do {
            _ = try jsonGenerator.validate(
                measurements: [measurement],
                baseline: baseline,
                metadata: metadata
            )
            XCTFail("Expected ExportError.invalidPath")
        } catch ExportError.invalidPath {
            // Expected
        } catch {
            XCTFail("Expected ExportError.invalidPath, got: \(error)")
        }
    }

    func testValidate_MismatchedMeasurementCount() {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 10, // Mismatch
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When/Then
        do {
            _ = try jsonGenerator.validate(
                measurements: measurements,
                baseline: baseline,
                metadata: metadata
            )
            XCTFail("Expected ExportError.encodingFailed")
        } catch ExportError.encodingFailed {
            // Expected
        } catch {
            XCTFail("Expected ExportError.encodingFailed, got: \(error)")
        }
    }

    func testValidate_InvalidBaseline() {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 0, // Invalid
            baselineHRV: 0, // Invalid
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When/Then
        do {
            _ = try jsonGenerator.validate(
                measurements: [measurement],
                baseline: baseline,
                metadata: metadata
            )
            XCTFail("Expected ExportError.encodingFailed")
        } catch ExportError.encodingFailed {
            // Expected
        } catch {
            XCTFail("Expected ExportError.encodingFailed, got: \(error)")
        }
    }

    // MARK: - Minimal JSON Tests

    func testGenerateMinimal_NoPrettyPrint() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 3)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 3,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generateMinimal(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        // Minimal JSON should be more compact
        XCTAssertFalse(json.contains("\n"))
    }

    func testGenerateMeasurementsOnly() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 3)

        // When
        let json = try jsonGenerator.generateMeasurementsOnly(from: measurements)

        // Then
        XCTAssertFalse(json.isEmpty)
        XCTAssertTrue(json.contains("\"timestamp\""))
        XCTAssertTrue(json.contains("\"stressLevel\""))
        // Should not include metadata, baseline, or summary
        XCTAssertFalse(json.contains("\"metadata\""))
        XCTAssertFalse(json.contains("\"baseline\""))
        XCTAssertFalse(json.contains("\"summary\""))
    }

    func testGenerateMeasurementsOnly_Empty() {
        // Given
        let measurements: [StressMeasurement] = []

        // When/Then
        do {
            _ = try jsonGenerator.generateMeasurementsOnly(from: measurements)
            XCTFail("Expected ExportError.noData")
        } catch ExportError.noData {
            // Expected
        } catch {
            XCTFail("Expected ExportError.noData")
        }
    }

    // MARK: - Custom Sorting Tests

    func testGenerateWithCustomSorting() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 5,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generateWithCustomSorting(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        // Should include header comment
        XCTAssertTrue(json.contains("_comment"))
        XCTAssertTrue(json.contains("_formatVersion"))
    }

    // MARK: - Error Handling Tests

    func testGenerateJSON_EmptyMeasurements() {
        // Given
        let measurements: [StressMeasurement] = []
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 0,
            startDate: Date(),
            endDate: Date(),
            format: .json
        )

        // When/Then
        do {
            _ = try jsonGenerator.generate(
                from: measurements,
                baseline: baseline,
                metadata: metadata
            )
            XCTFail("Expected ExportError.noData")
        } catch ExportError.noData {
            // Expected
        } catch {
            XCTFail("Expected ExportError.noData")
        }
    }

    // MARK: - Edge Cases Tests

    func testGenerateJSON_WithNilConfidences() throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: nil
        )
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        // Confidence should default to 0.0
        XCTAssertTrue(json.contains("0.0"))
    }

    func testGenerateJSON_WithEmptyConfidences() throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: []
        )
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
    }

    func testGenerateJSON_SingleMeasurement() throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        XCTAssertTrue(json.contains("\"totalMeasurements\": 1"))
    }

    func testGenerateJSON_LargeDataset() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 1000)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1000,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        XCTAssertTrue(json.contains("\"totalMeasurements\": 1000"))
    }

    // MARK: - JSON Structure Tests

    func testGenerateJSON_ValidJSONStructure() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 5,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then - Verify it's valid JSON by checking structure
        XCTAssertTrue(json.contains("\"metadata\":"))
        XCTAssertTrue(json.contains("\"baseline\":"))
        XCTAssertTrue(json.contains("\"measurements\":"))
        XCTAssertTrue(json.contains("\"summary\":"))
    }

    func testGenerateJSON_ISO8601Dates() throws {
        // Given
        let measurement = testDataFactory.createMeasurement()
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then - Dates should be in ISO8601 format
        XCTAssertTrue(json.contains("T") || json.contains("-"))
    }

    // MARK: - Stress Snapshot Tests

    func testStressSnapshot_ConfidenceCalculation() throws {
        // Given
        let measurement = StressMeasurement(
            timestamp: Date(),
            stressLevel: 50,
            hrv: 50,
            restingHeartRate: 60,
            confidences: [0.7, 0.8, 0.9]
        )
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 1,
            startDate: measurement.timestamp,
            endDate: measurement.timestamp,
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: [measurement],
            baseline: baseline,
            metadata: metadata
        )

        // Then - Confidence should be averaged
        // (0.7 + 0.8 + 0.9) / 3 = 0.8
        XCTAssertTrue(json.contains("0.8"))
    }

    // MARK: - Performance Tests

    func testPerformance_GenerateJSON() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 100)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 100,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // Measure
        measure {
            try? _ = jsonGenerator.generate(
                from: measurements,
                baseline: baseline,
                metadata: metadata
            )
        }
    }

    func testPerformance_Validate() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 100)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 100,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // Measure
        measure {
            try? _ = jsonGenerator.validate(
                measurements: measurements,
                baseline: baseline,
                metadata: metadata
            )
        }
    }

    // MARK: - Data Integrity Tests

    func testGenerateJSON_DataIntegrity() throws {
        // Given
        let originalMeasurements = testDataFactory.createMeasurementBatch(count: 10)
        let baseline = PersonalBaseline(
            restingHeartRate: 62,
            baselineHRV: 48,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 10,
            startDate: originalMeasurements.last?.timestamp ?? Date(),
            endDate: originalMeasurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json = try jsonGenerator.generate(
            from: originalMeasurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertFalse(json.isEmpty)
        // Should contain all stress levels
        for measurement in originalMeasurements {
            let stressLevelString = String(format: "%.1f", measurement.stressLevel)
            XCTAssertTrue(json.contains(stressLevelString))
        }
    }

    func testGenerateJSON_ReproducibleOutput() throws {
        // Given
        let measurements = testDataFactory.createMeasurementBatch(count: 5)
        let baseline = PersonalBaseline(
            restingHeartRate: 60,
            baselineHRV: 50,
            lastUpdated: Date()
        )
        let metadata = ExportMetadata(
            exportDate: Date(),
            deviceName: "iPhone",
            appVersion: "1.0",
            measurementCount: 5,
            startDate: measurements.last?.timestamp ?? Date(),
            endDate: measurements.first?.timestamp ?? Date(),
            format: .json
        )

        // When
        let json1 = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )
        let json2 = try jsonGenerator.generate(
            from: measurements,
            baseline: baseline,
            metadata: metadata
        )

        // Then
        XCTAssertEqual(json1, json2, "JSON output should be reproducible")
    }
}
