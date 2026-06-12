import Foundation
import SwiftData

// MARK: - Character Unlock Status

/// Tracks which characters the user has unlocked and their evolution progress.
/// Persisted via SwiftData.
@Model
final class CharacterUnlock {
    #Unique<CharacterUnlock>([\.characterId])

    var characterId: String        // "ripple", "blossom", etc.
    var isUnlocked: Bool
    var currentEvolution: String   // EvolutionStage rawValue
    var isActive: Bool             // Currently selected as active character
    var unlockedAt: Date?
    var lastEvolvedAt: Date?

    /// Streak days tracked for this character
    var streakDays: Int
    /// Breathing/mindfulness sessions completed toward evolution
    var sessionsCompleted: Int
    /// Resilience score at last check
    var resilienceScore: Double

    init(
        characterId: String,
        isUnlocked: Bool = false,
        currentEvolution: EvolutionStage = .droplet,
        isActive: Bool = false,
        streakDays: Int = 0,
        sessionsCompleted: Int = 0,
        resilienceScore: Double = 0
    ) {
        self.characterId = characterId
        self.isUnlocked = isUnlocked
        self.currentEvolution = currentEvolution.rawValue
        self.isActive = isActive
        self.unlockedAt = isUnlocked ? Date() : nil
        self.lastEvolvedAt = nil
        self.streakDays = streakDays
        self.sessionsCompleted = sessionsCompleted
        self.resilienceScore = resilienceScore
    }

    /// Typed evolution stage accessor
    var evolutionStage: EvolutionStage {
        get { EvolutionStage(rawValue: currentEvolution) ?? .droplet }
        set { currentEvolution = newValue.rawValue }
    }

    /// Check if character can evolve to next stage
    var canEvolve: Bool {
        let nextStages = EvolutionStage.allCases.filter { $0.sortOrder == evolutionStage.sortOrder + 1 }
        guard let next = nextStages.first else { return false }
        return meetsRequirements(for: next)
    }

    /// Progress toward next evolution (0.0 - 1.0)
    var evolutionProgress: Double {
        switch evolutionStage {
        case .droplet:
            // Need 30-day streak
            return min(Double(streakDays) / 30.0, 1.0)
        case .ripple:
            // Need 90-day streak + resilience 80+
            let streakProgress = min(Double(streakDays) / 90.0, 1.0)
            let resilienceProgress = min(resilienceScore / 80.0, 1.0)
            return min((streakProgress + resilienceProgress) / 2.0, 1.0)
        case .tidal:
            return 1.0 // Max evolution
        }
    }

    // MARK: - Evolution Requirements

    private func meetsRequirements(for stage: EvolutionStage) -> Bool {
        switch stage {
        case .droplet:
            return true
        case .ripple:
            return streakDays >= 30 && sessionsCompleted >= 5
        case .tidal:
            return streakDays >= 90 && resilienceScore >= 80
        }
    }
}

// MARK: - Preview Helpers

extension CharacterUnlock {
    /// Sample unlocks for previews
    static let previewUnlocks: [CharacterUnlock] = {
        var unlocks: [CharacterUnlock] = []
        // Ripple — free, unlocked, stage 2
        let ripple = CharacterUnlock(characterId: "ripple", isUnlocked: true, currentEvolution: .ripple, isActive: true, streakDays: 45, sessionsCompleted: 8)
        // Blossom — free, unlocked, stage 1
        let blossom = CharacterUnlock(characterId: "blossom", isUnlocked: true, currentEvolution: .droplet, streakDays: 12, sessionsCompleted: 2)
        // Ember — premium, locked
        let ember = CharacterUnlock(characterId: "ember", isUnlocked: false)
        // Zephyr — premium, locked
        let zephyr = CharacterUnlock(characterId: "zephyr", isUnlocked: false)
        // Lumi — streak-gated, locked
        let lumi = CharacterUnlock(characterId: "lumi", isUnlocked: false)
        return [ripple, blossom, ember, zephyr, lumi]
    }()
}
