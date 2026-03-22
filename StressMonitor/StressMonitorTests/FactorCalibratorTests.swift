import XCTest
@testable import StressMonitor

final class FactorCalibratorTests: XCTestCase {

    private let calibrator = FactorCalibrator()

    // MARK: - Insufficient data

    func testFewMeasurements_returnsDefaults() {
        let measurements = makeMeasurements(count: 29)
        let weights = calibrator.calibrate(from: measurements)
        XCTAssertEqual(weights.hrv, FactorWeights.defaults.hrv, accuracy: 0.001)
        XCTAssertEqual(weights.sleep, FactorWeights.defaults.sleep, accuracy: 0.001)
    }

    func testEmptyMeasurements_returnsDefaults() {
        let weights = calibrator.calibrate(from: [])
        XCTAssertEqual(weights.hrv, FactorWeights.defaults.hrv, accuracy: 0.001)
    }

    // MARK: - Weight clamping

    func testWeights_clampedToWithin25PercentOfDefaults() {
        // 30 measurements with extreme HRV variance → HRV weight should be clamped at max
        let measurements = makeMeasurements(count: 30, hrvComponents: [0.0, 1.0, 0.0, 1.0])
        let weights = calibrator.calibrate(from: measurements)

        XCTAssertLessThanOrEqual(weights.hrv, FactorWeights.defaults.hrv * 1.25 + 0.001)
        XCTAssertGreaterThanOrEqual(weights.hrv, FactorWeights.defaults.hrv * 0.75 - 0.001)
        XCTAssertLessThanOrEqual(weights.heartRate, FactorWeights.defaults.heartRate * 1.25 + 0.001)
        XCTAssertGreaterThanOrEqual(weights.heartRate, FactorWeights.defaults.heartRate * 0.75 - 0.001)
        XCTAssertLessThanOrEqual(weights.sleep, FactorWeights.defaults.sleep * 1.25 + 0.001)
        XCTAssertGreaterThanOrEqual(weights.sleep, FactorWeights.defaults.sleep * 0.75 - 0.001)
    }

    func testAllZeroVariance_returnsDefaults() {
        // All components identical → zero variance for all → returns defaults
        let measurements = makeMeasurements(count: 30, hrvComponents: Array(repeating: 0.5, count: 30))
        let weights = calibrator.calibrate(from: measurements)
        XCTAssertEqual(weights.hrv, FactorWeights.defaults.hrv, accuracy: 0.001)
    }

    // MARK: - Hourly baseline

    func testHourlyBaseline_computesAveragePerHour() {
        let cal = Calendar.current
        var measurements: [StressMeasurement] = []

        // Add 5 measurements at hour 8 with hrv=60
        for _ in 0..<5 {
            let date = cal.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
            let m = makeMeasurement(timestamp: date, hrv: 60)
            measurements.append(m)
        }

        let hourly = calibrator.calculateHourlyBaseline(from: measurements)
        XCTAssertNotNil(hourly[8])
        XCTAssertEqual(hourly[8]!, 60.0, accuracy: 0.01)
    }

    func testHourlyBaseline_omitsHoursWith_fewerThan5Samples() {
        let cal = Calendar.current
        var measurements: [StressMeasurement] = []

        // Only 4 measurements at hour 10 → should be omitted
        for _ in 0..<4 {
            let date = cal.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
            measurements.append(makeMeasurement(timestamp: date, hrv: 55))
        }

        let hourly = calibrator.calculateHourlyBaseline(from: measurements)
        XCTAssertNil(hourly[10], "Hours with <5 samples should be excluded")
    }

    func testHourlyBaseline_emptyInput_returnsEmpty() {
        let hourly = calibrator.calculateHourlyBaseline(from: [])
        XCTAssertTrue(hourly.isEmpty)
    }

    // MARK: - DataQualityInfo thresholds

    func testQualityLevel_excellent() {
        let info = DataQualityInfo(activeFactors: ["hrv", "heartRate", "sleep", "activity", "recovery"],
                                   missingFactors: [], dataCompleteness: 1.0,
                                   isCalibrated: false, lastCalibrationDate: nil)
        XCTAssertEqual(info.qualityLevel, .excellent)
    }

    func testQualityLevel_good() {
        let info = DataQualityInfo(activeFactors: ["hrv", "heartRate", "sleep"],
                                   missingFactors: ["activity", "recovery"], dataCompleteness: 0.75,
                                   isCalibrated: false, lastCalibrationDate: nil)
        XCTAssertEqual(info.qualityLevel, .good)
    }

    func testQualityLevel_limited() {
        let info = DataQualityInfo(activeFactors: ["hrv", "heartRate"],
                                   missingFactors: ["sleep", "activity", "recovery"], dataCompleteness: 0.40,
                                   isCalibrated: false, lastCalibrationDate: nil)
        XCTAssertEqual(info.qualityLevel, .limited)
    }

    func testQualityLevel_minimal() {
        let info = DataQualityInfo(activeFactors: ["hrv"],
                                   missingFactors: ["heartRate", "sleep", "activity", "recovery"],
                                   dataCompleteness: 0.25, isCalibrated: false, lastCalibrationDate: nil)
        XCTAssertEqual(info.qualityLevel, .minimal)
    }

    // MARK: - PersonalBaseline calibration fields

    func testPersonalBaseline_calibrationFieldsDefault_nil() {
        let baseline = PersonalBaseline()
        XCTAssertNil(baseline.factorWeights)
        XCTAssertNil(baseline.hourlyHRVBaseline)
        XCTAssertNil(baseline.calibrationDate)
    }

    func testPersonalBaseline_encodesCalibrationFields() throws {
        var baseline = PersonalBaseline()
        baseline.factorWeights = .defaults
        baseline.calibrationDate = Date(timeIntervalSince1970: 0)

        let data = try JSONEncoder().encode(baseline)
        let decoded = try JSONDecoder().decode(PersonalBaseline.self, from: data)

        XCTAssertNotNil(decoded.factorWeights)
        XCTAssertEqual(decoded.factorWeights!.hrv, FactorWeights.defaults.hrv, accuracy: 0.001)
        XCTAssertEqual(decoded.calibrationDate!.timeIntervalSince1970, 0, accuracy: 1)
    }

    // MARK: - Helpers

    private func makeMeasurement(timestamp: Date = Date(), hrv: Double = 50) -> StressMeasurement {
        let m = StressMeasurement(timestamp: timestamp, stressLevel: 30, hrv: hrv,
                                   restingHeartRate: 60)
        m.hrvComponent = 0.3
        m.hrComponent = 0.2
        m.sleepComponent = 0.4
        m.activityComponent = 0.3
        m.recoveryComponent = 0.2
        return m
    }

    private func makeMeasurements(count: Int, hrvComponents: [Double]? = nil) -> [StressMeasurement] {
        (0..<count).map { i in
            let m = StressMeasurement(timestamp: Date(), stressLevel: 30, hrv: 50,
                                       restingHeartRate: 60)
            if let hrv = hrvComponents {
                m.hrvComponent = hrv[i % hrv.count]
                m.hrComponent = 0.2
                m.sleepComponent = 0.3
                m.activityComponent = 0.25
                m.recoveryComponent = 0.15
            } else {
                m.hrvComponent = Double.random(in: 0...1)
                m.hrComponent = Double.random(in: 0...1)
                m.sleepComponent = Double.random(in: 0...1)
                m.activityComponent = Double.random(in: 0...1)
                m.recoveryComponent = Double.random(in: 0...1)
            }
            return m
        }
    }
}
