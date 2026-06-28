import Foundation
import Observation

/// Loads and updates the three daily habits shown on the Action tab.
///
/// The watch app does not use SwiftData. One row per habit per day is kept in
/// `UserDefaults`. On first load of a day with no rows, AUTO habits
/// (hydration, sunlight) are seeded at 0 so they render with their AUTO pill
/// immediately; the LOG habit (caffeine) is seeded the same way and bumped via
/// `logManual(_:amount:)`.
@Observable
@MainActor
final class WatchHabitViewModel {
    /// Today's habit rows, keyed by HabitType for O(1) lookup in the view.
    private(set) var today: [HabitType: WatchHabit] = [:]

    /// Storage key for the persisted `[WatchHabit]` array (today's rows only).
    private let storageKey = "WatchHabitViewModel.today"

    init() {
        loadToday()
    }

    // MARK: - Read

    func habit(for type: HabitType) -> WatchHabit? {
        today[type]
    }

    // MARK: - Write

    /// Add to a habit's current value (e.g. tapping "+" on a cup of water).
    func logManual(_ type: HabitType, amount: Double = 1) {
        guard let habit = today[type] else { return }
        today[type]?.currentValue = min(habit.goalValue * 2, habit.currentValue + amount)
        save()
    }

    /// Replace the live value of an AUTO habit (HealthKit feed updates this).
    func setAutoValue(_ type: HabitType, value: Double) {
        guard today[type] != nil else { return }
        today[type]?.currentValue = max(0, value)
        save()
    }

    // MARK: - Loading

    func loadToday() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        var byType: [HabitType: WatchHabit] = [:]

        // Restore today's rows from UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let rows = try? JSONDecoder().decode([WatchHabit].self, from: data) {
            for row in rows where calendar.isDate(row.date, inSameDayAs: startOfDay) {
                byType[row.type] = row
            }
        }

        // Seed any missing habit types for today so every row renders
        for type in HabitType.allCases where byType[type] == nil {
            byType[type] = WatchHabit(type: type, date: startOfDay)
        }

        today = byType
        save()
    }

    // MARK: - Persistence

    private func save() {
        let rows = Array(today.values)
        if let data = try? JSONEncoder().encode(rows) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
