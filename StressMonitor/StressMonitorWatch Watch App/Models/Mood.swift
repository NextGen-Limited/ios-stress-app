import Foundation

/// Five-level mood scale used by the watch mood logger.
public enum WatchMood: String, CaseIterable, Codable, Sendable, Identifiable {
    case great
    case good
    case okay
    case stressed
    case awful

    public var id: String { rawValue }

    /// Capitalised display name ("Great", "Good", …).
    public var displayName: String {
        switch self {
        case .great:    return "Great"
        case .good:     return "Good"
        case .okay:     return "Okay"
        case .stressed: return "Stressed"
        case .awful:    return "Awful"
        }
    }

    /// SF Symbol icon for this mood.
    public var icon: String {
        switch self {
        case .great:    return "face.smiling.inverse"
        case .good:     return "face.smiling"
        case .okay:     return "face.dashed"
        case .stressed: return "face.dashed.fill"
        case .awful:    return "frown"
        }
    }
}

/// A single mood entry logged by the user on the watch.
public struct WatchMoodLog: Identifiable, Sendable, Codable {
    public let id: UUID
    public let mood: WatchMood
    public let timestamp: Date
    public let note: String?
    public let stressLevel: Double?

    public init(
        id: UUID = UUID(),
        mood: WatchMood,
        timestamp: Date = Date(),
        note: String? = nil,
        stressLevel: Double? = nil
    ) {
        self.id = id
        self.mood = mood
        self.timestamp = timestamp
        self.note = note
        self.stressLevel = stressLevel
    }
}
