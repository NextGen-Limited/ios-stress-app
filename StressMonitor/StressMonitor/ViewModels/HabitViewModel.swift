import Foundation
import Observation
import SwiftData

/// Loads and updates the three daily habits shown on the Action tab.
///
/// One row per habit per day is kept in SwiftData. On first load of a day with
/// no rows, AUTO habits (hydration, sunlight) are seeded at 0 so they render
/// with their AUTO pill immediately; the LOG habit (caffeine) is seeded the same
/// way and bumped via `logManual(_:amount:)`.
@Observable
@MainActor
final class HabitViewModel {
    /// Today's habit rows, keyed by HabitType for O(1) lookup in the view.
    private(set) var today: [HabitType: Habit] = [:]

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadToday()
    }

    // MARK: - Read

    func habit(for type: HabitType) -> Habit? {
        today[type]
    }

    // MARK: - Write

    /// Add to a habit's current value (e.g. tapping "+" on a cup of water).
    func logManual(_ type: HabitType, amount: Double = 1) {
        guard let habit = today[type] else { return }
        habit.currentValue = min(habit.goalValue * 2, habit.currentValue + amount)
        save()
    }

    /// Replace the live value of an AUTO habit (HealthKit feed updates this).
    func setAutoValue(_ type: HabitType, value: Double) {
        guard let habit = today[type] else { return }
        habit.currentValue = max(0, value)
        save()
    }

    // MARK: - Loading

    func loadToday() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.date >= startOfDay }
        )

        let rows = (try? modelContext.fetch(descriptor)) ?? []

        // Index existing rows by type
        var byType: [HabitType: Habit] = [:]
        for row in rows where byType[row.type] == nil {
            byType[row.type] = row
        }

        // Seed any missing habit types for today so every row renders
        for type in HabitType.allCases where byType[type] == nil {
            let habit = Habit(type: type, date: startOfDay)
            modelContext.insert(habit)
            byType[type] = habit
        }

        today = byType
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}
