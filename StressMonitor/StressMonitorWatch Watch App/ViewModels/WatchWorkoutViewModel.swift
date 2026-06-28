import Foundation
import Observation

// MARK: - WatchWorkoutViewModel

/// Tracks live heart-rate data during a workout, surfacing the current
/// zone, elapsed time, and per-zone time distribution for the workout view.
///
/// The view model is intentionally source-agnostic: callers feed it heart
/// rate samples via `updateHR(_:)` (e.g. from a HealthKit workout session
/// or a mock generator). State lives on `@MainActor` to keep SwiftUI reads
/// safe.
@MainActor
@Observable
final class WatchWorkoutViewModel {
    /// Most recent heart-rate sample (BPM).
    var currentHR: Double = 0

    /// Zone for `currentHR` given the configured max HR.
    private(set) var currentZone: WorkoutZone = .zone1

    /// Workout elapsed time in whole seconds.
    var elapsedSeconds: Int = 0

    /// Total seconds accumulated in each zone during this workout.
    private(set) var zoneTimeSummary: [WorkoutZone: Int] = [:]

    /// `true` while a workout is running and the timer is ticking.
    var isRunning: Bool = false

    /// Configured maximum heart rate used for zone resolution.
    private(set) var maxHR: Double = 190

    private var secondTicker: Task<Void, Never>?

    // MARK: - Lifecycle

    /// Begin tracking. Resets accumulated stats and starts the elapsed timer.
    func start(maxHR: Double = 190) {
        guard !isRunning else { return }
        self.maxHR = max(maxHR, 1)
        currentHR = 0
        currentZone = .zone1
        elapsedSeconds = 0
        zoneTimeSummary = [:]
        for zone in WorkoutZone.allCases {
            zoneTimeSummary[zone] = 0
        }
        isRunning = true
        startTicker()
    }

    /// Stop tracking and tear down the timer.
    func stop() {
        isRunning = false
        secondTicker?.cancel()
        secondTicker = nil
    }

    /// Feed a new heart-rate sample (BPM) into the view model.
    func updateHR(_ hr: Double) {
        currentHR = max(0, hr)
        let zone = WorkoutZone.zone(for: hr, maxHR: maxHR)
        currentZone = zone
        // Attribute one second of zone time at the boundary the sample
        // arrives on (the per-second ticker also advances the active zone).
        if isRunning {
            zoneTimeSummary[zone, default: 0] += 1
        }
    }

    // MARK: - Internals

    private func startTicker() {
        secondTicker = Task { @MainActor [weak self] in
            while let self, self.isRunning {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, self.isRunning else { break }
                self.elapsedSeconds += 1
            }
        }
    }
}
