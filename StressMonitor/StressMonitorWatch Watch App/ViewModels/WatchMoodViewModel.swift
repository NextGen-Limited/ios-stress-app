import Foundation
import Observation

/// Manages the mood log on the watch, persisted to `UserDefaults`.
///
/// The watch app does not use SwiftData. Mood logs are encoded as a
/// `[WatchMoodLog]` array in `UserDefaults`. The view model exposes the most
/// recent logs (capped for watch UI performance) plus helpers for logging a
/// new mood and clearing history.
@Observable
@MainActor
final class WatchMoodViewModel {
    /// All mood logs, newest first.
    private(set) var logs: [WatchMoodLog] = []

    /// Most recent log, if any.
    var latest: WatchMoodLog? { logs.first }

    /// Maximum number of logs retained on the watch.
    static let maxLogs = 100

    /// Storage key for the persisted `[WatchMoodLog]` array.
    private let storageKey = "WatchMoodViewModel.logs"

    init() {
        load()
    }

    // MARK: - Write

    /// Log a new mood entry. Stored newest-first.
    @discardableResult
    func log(
        mood: WatchMood,
        note: String? = nil,
        stressLevel: Double? = nil,
        timestamp: Date = Date()
    ) -> WatchMoodLog {
        let entry = WatchMoodLog(
            mood: mood,
            timestamp: timestamp,
            note: note,
            stressLevel: stressLevel
        )
        logs.insert(entry, at: 0)
        if logs.count > Self.maxLogs {
            logs = Array(logs.prefix(Self.maxLogs))
        }
        save()
        return entry
    }

    /// Remove a specific log by id.
    func remove(_ id: UUID) {
        logs.removeAll { $0.id == id }
        save()
    }

    /// Clear all mood logs.
    func clearAll() {
        logs.removeAll()
        save()
    }

    // MARK: - Loading

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WatchMoodLog].self, from: data)
        else {
            logs = []
            return
        }
        // Keep newest-first and enforce cap.
        logs = Array(decoded.prefix(Self.maxLogs))
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
