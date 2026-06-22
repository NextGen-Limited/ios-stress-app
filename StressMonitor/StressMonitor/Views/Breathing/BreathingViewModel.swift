import SwiftUI
import SwiftData

@Observable
@MainActor
class BreathingSessionViewModel {
    var sessionDuration: TimeInterval = 120
    var remainingTime: TimeInterval = 120
    var isActive = false
    var sessionResult: BreathingSessionResult?

    /// Single source of truth for the 4-4-4-4 box-breathing phase.
    var boxPhase: BoxBreathingPhase = .inhale
    /// Seconds remaining in the current 4-second box phase.
    var secondsRemaining: Int = 4

    private let healthKit: HealthKitServiceProtocol
    private var timer: Timer?
    private var phaseTickTimer: Timer?
    private var preSessionHRV: Double?
    private var postSessionHRV: Double?

    enum BreathingPhase {
        case inhale
        case hold
        case exhale
    }

    init(healthKit: HealthKitServiceProtocol) {
        self.healthKit = healthKit
    }

    convenience init() {
        self.init(healthKit: HealthKitManager())
    }

    func startSession() {
        isActive = true
        remainingTime = sessionDuration
        boxPhase = .inhale
        secondsRemaining = BoxBreathingPhase.inhale.durationSeconds

        Task {
            if let hrv = try? await healthKit.fetchLatestHRV() {
                preSessionHRV = hrv.value
            }
        }

        startBoxPhaseTicks()
        startCountdown()
    }

    func endSession() {
        isActive = false
        timer?.invalidate()
        phaseTickTimer?.invalidate()
        phaseTickTimer = nil

        Task {
            if let hrv = try? await healthKit.fetchLatestHRV() {
                postSessionHRV = hrv.value
            }

            if let pre = preSessionHRV, let post = postSessionHRV {
                sessionResult = BreathingSessionResult(
                    preSessionHRV: pre,
                    postSessionHRV: post,
                    duration: sessionDuration - remainingTime,
                    cyclesCompleted: Int((sessionDuration - remainingTime) / 16)
                )
            }
        }
    }

    /// Steps the 4-4-4-4 box-breathing phase every second, advancing through
    /// inhale → holdIn → exhale → holdOut → inhale.
    private func startBoxPhaseTicks() {
        guard isActive else { return }
        phaseTickTimer?.invalidate()
        phaseTickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isActive else { return }
                if self.secondsRemaining > 1 {
                    self.secondsRemaining -= 1
                } else {
                    self.advanceBoxPhase()
                }
            }
        }
    }

    private func advanceBoxPhase() {
        switch boxPhase {
        case .inhale:  boxPhase = .holdIn
        case .holdIn:  boxPhase = .exhale
        case .exhale:  boxPhase = .holdOut
        case .holdOut: boxPhase = .inhale
        }
        secondsRemaining = boxPhase.durationSeconds
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.remainingTime <= 0 { return }

                self.remainingTime -= 1

                if self.remainingTime <= 0 {
                    self.endSession()
                    NotificationCenter.default.post(name: .breathingSessionComplete, object: self.sessionResult)
                }
            }
        }
    }
}

struct BreathingSessionResult {
    let preSessionHRV: Double
    let postSessionHRV: Double
    let duration: TimeInterval
    let cyclesCompleted: Int

    var improvement: Double {
        postSessionHRV - preSessionHRV
    }

    var percentageImprovement: Double {
        (improvement / preSessionHRV) * 100
    }

    var stressChange: StressChangeCategory {
        if improvement > 10 { return .improved }
        if improvement < -10 { return .declined }
        return .stable
    }
}

enum StressChangeCategory {
    case improved
    case stable
    case declined
}

extension Notification.Name {
    static let breathingSessionComplete = Notification.Name("breathingSessionComplete")
}
