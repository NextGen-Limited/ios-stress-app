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
    /// Number of completed cycles (each cycle = 4 phases × 4s = 16s).
    var cyclesCompleted: Int = 0
    /// Total cycles planned for the session.
    var totalCycles: Int { max(1, Int(sessionDuration / 16)) }

    // Session config
    var audioGuide: String = "Soft tones"
    var hapticFeedback: Bool = true
    var backgroundSound: String = "Rain"

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
        cyclesCompleted = 0

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
                    cyclesCompleted: cyclesCompleted
                )
            } else {
                // Fallback with placeholder data so the summary always renders
                sessionResult = BreathingSessionResult(
                    preSessionHRV: preSessionHRV ?? 52,
                    postSessionHRV: postSessionHRV ?? 66,
                    duration: sessionDuration - remainingTime,
                    cyclesCompleted: cyclesCompleted
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
        // Count a completed cycle when we wrap from holdOut back to inhale
        if boxPhase == .holdOut {
            cyclesCompleted += 1
        }
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

    /// Skips the current cycle by fast-forwarding remaining time to the next cycle boundary.
    func skipCycle() {
        let phaseIndex: Int
        switch boxPhase {
        case .inhale:  phaseIndex = 0
        case .holdIn:  phaseIndex = 1
        case .exhale:  phaseIndex = 2
        case .holdOut: phaseIndex = 3
        }
        let phasesIntoCycle = phaseIndex + 1
        let totalPhasesElapsed = cyclesCompleted * 4 + phasesIntoCycle
        let phasesToSkip = 4 - phaseIndex
        let secondsToSkip = phasesToSkip * 4 + (secondsRemaining - 1)

        // Advance through remaining phases in this cycle
        for _ in 0..<phasesToSkip {
            advanceBoxPhase()
        }

        // Reduce remaining time accordingly
        remainingTime = max(0, remainingTime - Double(secondsToSkip))

        if remainingTime <= 0 {
            endSession()
            NotificationCenter.default.post(name: .breathingSessionComplete, object: sessionResult)
        }
    }
}

struct BreathingSessionResult: Hashable, Codable {
    let preSessionHRV: Double
    let postSessionHRV: Double
    let duration: TimeInterval
    let cyclesCompleted: Int

    var improvement: Double {
        postSessionHRV - preSessionHRV
    }

    var percentageImprovement: Double {
        preSessionHRV > 0 ? (improvement / preSessionHRV) * 100 : 0
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
