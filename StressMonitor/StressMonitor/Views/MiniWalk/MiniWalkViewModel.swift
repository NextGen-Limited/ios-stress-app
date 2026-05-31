import Foundation
import SwiftUI

@Observable
@MainActor
final class MiniWalkViewModel {

    // MARK: - State

    var remainingSeconds: Int
    var isRunning = false
    var isFinished = false

    // MARK: - Config

    var durationSeconds: Int = 45
    let instruction = "Walk at a brisk pace. Focus on breathing. Be present."

    // MARK: - Computed

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(durationSeconds)
    }

    var timeDisplay: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Private

    private var timer: Timer?

    init(durationSeconds: Int = 45) {
        self.durationSeconds = durationSeconds
        self.remainingSeconds = durationSeconds
    }

    // MARK: - Actions

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isFinished = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.remainingSeconds -= 1

                if self.remainingSeconds <= 0 {
                    self.remainingSeconds = 0
                    self.isRunning = false
                    self.isFinished = true
                    self.timer?.invalidate()
                    self.timer = nil
                    HapticManager.shared.success()
                }
            }
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isFinished = false
        remainingSeconds = durationSeconds
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}
