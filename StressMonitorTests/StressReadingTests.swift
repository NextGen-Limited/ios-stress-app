import XCTest
@testable import StressMonitor

final class StressReadingTests: XCTestCase {
    
    // MARK: - StressReading Tests
    
    func testStressReadingInitialization() {
        let id = UUID()
        let timestamp = Date()
        let reading = StressReading(
            id: id,
            timestamp: timestamp,
            level: 0.45,
            hrv: 55,
            heartRate: 72,
            source: .appleWatch
        )
        
        XCTAssertEqual(reading.id, id)
        XCTAssertEqual(reading.timestamp, timestamp)
        XCTAssertEqual(reading.level, 0.45)
        XCTAssertEqual(reading.hrv, 55)
        XCTAssertEqual(reading.heartRate, 72)
        XCTAssertEqual(reading.source, .appleWatch)
    }
    
    func testStressReadingCodable() throws {
        let original = StressReading(
            id: UUID(),
            timestamp: Date(),
            level: 0.65,
            hrv: 42,
            heartRate: 88,
            source: .manual
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StressReading.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.level, original.level, accuracy: 0.001)
        XCTAssertEqual(decoded.hrv, original.hrv, accuracy: 0.001)
        XCTAssertEqual(decoded.heartRate, original.heartRate, accuracy: 0.001)
        XCTAssertEqual(decoded.source, original.source)
    }
    
    func testStressReadingIdentifiable() {
        let reading1 = StressReading(
            id: UUID(),
            timestamp: Date(),
            level: 0.3,
            hrv: 60,
            heartRate: 70,
            source: .appleWatch
        )
        let reading2 = StressReading(
            id: UUID(),
            timestamp: Date(),
            level: 0.7,
            hrv: 30,
            heartRate: 100,
            source: .appleWatch
        )
        
        XCTAssertNotEqual(reading1.id, reading2.id)
    }
    
    func testDataSourceRawValues() {
        XCTAssertEqual(StressReading.DataSource.appleWatch.rawValue, "appleWatch")
        XCTAssertEqual(StressReading.DataSource.manual.rawValue, "manual")
        XCTAssertEqual(StressReading.DataSource.estimated.rawValue, "estimated")
    }
    
    // MARK: - StressSession Tests
    
    func testStressSessionInitialization() {
        let id = UUID()
        let startDate = Date()
        let readings = [
            StressReading(id: UUID(), timestamp: startDate, level: 0.3, hrv: 60, heartRate: 70, source: .appleWatch),
            StressReading(id: UUID(), timestamp: startDate.addingTimeInterval(60), level: 0.5, hrv: 45, heartRate: 80, source: .appleWatch)
        ]
        
        let session = StressSession(
            id: id,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(120),
            averageLevel: 0.4,
            peakLevel: 0.5,
            readings: readings
        )
        
        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.startDate, startDate)
        XCTAssertNotNil(session.endDate)
        XCTAssertEqual(session.averageLevel, 0.4)
        XCTAssertEqual(session.peakLevel, 0.5)
        XCTAssertEqual(session.readings.count, 2)
    }
    
    func testStressSessionCodable() throws {
        let original = StressSession(
            id: UUID(),
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            averageLevel: 0.45,
            peakLevel: 0.78,
            readings: []
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StressSession.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.averageLevel, original.averageLevel, accuracy: 0.001)
        XCTAssertEqual(decoded.peakLevel, original.peakLevel, accuracy: 0.001)
        XCTAssertEqual(decoded.readings.count, original.readings.count)
    }
    
    func testStressSessionWithNilEndDate() {
        let session = StressSession(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            averageLevel: 0.3,
            peakLevel: 0.3,
            readings: []
        )
        
        XCTAssertNil(session.endDate, "endDate should be nil for ongoing sessions")
    }
    
    // MARK: - StressMeasurement Tests (SwiftData model)
    
    func testStressMeasurementInitialization() {
        let measurement = StressMeasurement(
            stressLevel: 0.65,
            hrv: 42,
            heartRate: 88
        )
        
        XCTAssertEqual(measurement.stressLevel, 0.65)
        XCTAssertEqual(measurement.hrv, 42)
        XCTAssertEqual(measurement.heartRate, 88)
        XCTAssertEqual(measurement.source, "appleWatch") // Default source
    }
    
    func testStressMeasurementFromReading() {
        let reading = StressReading(
            id: UUID(),
            timestamp: Date(),
            level: 0.55,
            hrv: 50,
            heartRate: 75,
            source: .manual
        )
        
        let measurement = StressMeasurement.from(reading: reading)
        
        XCTAssertEqual(measurement.id, reading.id)
        XCTAssertEqual(measurement.stressLevel, reading.level, accuracy: 0.001)
        XCTAssertEqual(measurement.hrv, reading.hrv, accuracy: 0.001)
        XCTAssertEqual(measurement.heartRate, reading.heartRate, accuracy: 0.001)
        XCTAssertEqual(measurement.source, reading.source.rawValue)
    }
    
    func testStressMeasurementToReading() {
        let measurement = StressMeasurement(
            stressLevel: 0.45,
            hrv: 55,
            heartRate: 80,
            source: "estimated"
        )
        
        let reading = measurement.toReading()
        
        XCTAssertEqual(reading.id, measurement.id)
        XCTAssertEqual(reading.level, measurement.stressLevel, accuracy: 0.001)
        XCTAssertEqual(reading.hrv, measurement.hrv, accuracy: 0.001)
        XCTAssertEqual(reading.heartRate, measurement.heartRate, accuracy: 0.001)
        XCTAssertEqual(reading.source, .estimated)
    }
    
    func testStressMeasurementRecordType() {
        XCTAssertEqual(StressMeasurement.recordType, "StressMeasurement")
    }
}
