import Foundation

/// Subjective mood the user self-reports from the Home tab check-in.
/// Raw value doubles as a 1–5 ordinal scale (1 = calmest, 5 = most tense).
enum MoodLevel: Int, CaseIterable, Codable, Sendable, Identifiable {
    case veryCalm = 1
    case calm = 2
    case neutral = 3
    case tense = 4
    case veryTense = 5

    var id: Int { rawValue }

    /// Unicode glyph for the chip — NOT an emoji, per the no-emoji-as-icon rule.
    var glyph: String {
        switch self {
        case .veryCalm:  return "\u{25CC}" // ◌
        case .calm:      return "\u{25CE}" // ◎
        case .neutral:   return "\u{25D0}" // ◐
        case .tense:     return "\u{25D1}" // ◑
        case .veryTense: return "\u{25CF}" // ●
        }
    }

    /// Self-report labels from the Home check-in.
    /// Maps 1–5 to the 04-home spec chips: Calm / Focused / Tense / Wired / Fried.
    var displayName: String {
        switch self {
        case .veryCalm:  return "Calm"
        case .calm:      return "Focused"
        case .neutral:   return "Tense"
        case .tense:     return "Wired"
        case .veryTense: return "Fried"
        }
    }
}

/// One mood self-report. Held in-memory on the view model; persistence to
/// SwiftData is a later concern.
struct MoodEntry: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let level: MoodLevel

    init(id: UUID = UUID(), timestamp: Date = Date(), level: MoodLevel) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
    }
}
