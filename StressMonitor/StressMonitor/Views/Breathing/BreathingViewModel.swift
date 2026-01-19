import SwiftUI
import SwiftData

@Observable
@MainActor
class BreathingSessionViewModel {
    var sessionDuration: TimeInterval = 120
    var remainingTime: TimeInterval = 120
    var breathingPhase: BreathingPhase = .inhale
    var circleScale: Double = 1.0
    var isActive = false
    var sessionResult: BreathingSessionResult?

    private let healthKit: HealthKitServiceProtocol
    private var timer: Timer?
    private var breathingTimer: Timer?
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
        circleScale = 1.0

        Task {
            if let hrv = try? await healthKit.fetchLatestHRV() {
                preSessionHRV = hrv.value
            }
        }

        startBreathingCycle()
        startCountdown()
    }

    func endSession() {
        isActive = false
        timer?.invalidate()
        breathingTimer?.invalidate()

        Task {
            if let hrv = try? await healthKit.fetchLatestHRV() {
                postSessionHRV = hrv.value
            }

            if let pre = preSessionHRV, let post = postSessionHRV {
                sessionResult = BreathingSessionResult(
                    preSessionHRV: pre,
                    postSessionHRV: post,
                    duration: sessionDuration - remainingTime,
                    cyclesCompleted: Int((sessionDuration - remainingTime) / 10)
                )
            }
        }
    }

    private func startBreathingCycle() {
        guard isActive else { return }

        breathingPhase = .inhale
        animateCircle(to: 1.4, duration: 4.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, self.isActive else { return }

            self.breathingPhase = .hold

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.isActive else { return }

                self.breathingPhase = .exhale
                self.animateCircle(to: 0.6, duration: 6.0)

                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                    self?.startBreathingCycle()
                }
            }
        }
    }

    private func animateCircle(to scale: Double, duration: TimeInterval) {
        withAnimation(.easeInOut(duration: duration)) {
            circleScale = scale
        }
    }

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.remainingTime > 0 else {
                    return
                }

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
