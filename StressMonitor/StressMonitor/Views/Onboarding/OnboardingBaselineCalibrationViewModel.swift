import Foundation

@MainActor
@Observable
final class OnboardingBaselineCalibrationViewModel {
    var currentDay: Int = 1
    var calibrationCompleted: Bool = false
    var dailyMeasurementTaken: Bool = false

    private let repository: StressRepositoryProtocol

    init(repository: StressRepositoryProtocol) {
        self.repository = repository
        loadCalibrationState()
    }

    func startCalibration() {
        currentDay = 1
        dailyMeasurementTaken = false
        saveCalibrationState()
    }

    func recordDailyMeasurement() async {
        // Capture HRV/HR reading for baseline
        // This would trigger the measurement flow
        dailyMeasurementTaken = true
        saveCalibrationState()

        // Auto-advance to next day after measurement
        if currentDay < 7 {
            currentDay += 1
            dailyMeasurementTaken = false
        } else {
            calibrationCompleted = true
        }
        saveCalibrationState()
    }

    var currentPhase: CalibrationPhase {
        switch currentDay {
        case 1...3: return .learning
        case 4...5: return .calibration
        case 6...7: return .validation
        default: return .complete
        }
    }

    func completeCalibration() {
        // Mark baseline as ready
        UserDefaults.standard.set(true, forKey: "baselineCalibrated")
    }

    private func saveCalibrationState() {
        UserDefaults.standard.set(currentDay, forKey: "calibrationDay")
        UserDefaults.standard.set(calibrationCompleted, forKey: "calibrationCompleted")
    }

    private func loadCalibrationState() {
        currentDay = UserDefaults.standard.integer(forKey: "calibrationDay")
        calibrationCompleted = UserDefaults.standard.bool(forKey: "calibrationCompleted")
        if currentDay == 0 { currentDay = 1 }
    }
}

enum CalibrationPhase {
    case learning
    case calibration
    case validation
    case complete
}
