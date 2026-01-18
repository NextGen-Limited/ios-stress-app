import Foundation
import Testing
@testable import StressMonitor

struct StressMonitorTests {

    @Test func testObservableModel_setError() {
        let model = ObservableModel()
        model.setError("Test error")
        #expect(model.errorMessage == "Test error")
    }

    @Test func testObservableModel_clearError() {
        let model = ObservableModel()
        model.setError("Test error")
        model.clearError()
        #expect(model.errorMessage == nil)
    }

    @Test func testObservableModel_initialState() {
        let model = ObservableModel()
        #expect(model.isLoading == false)
        #expect(model.errorMessage == nil)
    }

    @Test func testHRVMeasurement_init() {
        let hrv = HRVMeasurement(value: 50.0)
        #expect(hrv.value == 50.0)
        #expect(hrv.unit == "ms")
        #expect(hrv.id != UUID())
    }

    @Test func testHRVMeasurement_codable() throws {
        let hrv = HRVMeasurement(value: 45.5, timestamp: Date(timeIntervalSince1970: 1000))
        let data = try JSONEncoder().encode(hrv)
        let decoded = try JSONDecoder().decode(HRVMeasurement.self, from: data)
        #expect(decoded.value == hrv.value)
        #expect(decoded.unit == hrv.unit)
    }

    @Test func testHeartRateSample_init() {
        let hr = HeartRateSample(value: 72.0)
        #expect(hr.value == 72.0)
        #expect(hr.id != UUID())
    }

    @Test func testHeartRateSample_codable() throws {
        let hr = HeartRateSample(value: 80.0, timestamp: Date(timeIntervalSince1970: 2000))
        let data = try JSONEncoder().encode(hr)
        let decoded = try JSONDecoder().decode(HeartRateSample.self, from: data)
        #expect(decoded.value == hr.value)
    }
}
