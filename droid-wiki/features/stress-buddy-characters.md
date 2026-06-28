# Stress Buddy characters

The gamification layer. Each user picks a companion creature whose mood and evolution stage reflect their stress patterns. Five creatures ship, each tied to an element. Evolution is gated by streaks, sessions, and resilience score, or unlocked through IAP.

## Characters

| ID | Name | Element | Color | Unlock |
| --- | --- | --- | --- | --- |
| ripple | Ripple | Water | #4FC3F7 | Free (default) |
| blossom | Blossom | Earth | #A5D6A7 | Free |
| ember | Ember | Fire | #FFAB91 | Premium |
| zephyr | Zephyr | Air | #D1C4E9 | Premium |
| lumi | Lumi | Moon | #7986CB | Streak-gated |

Defined in `StressMonitor/StressMonitor/Models/Character/CharacterCreature.swift`.

## Evolution stages

Each character has three growth stages (Tamagotchi-style):

| Stage | Name | Unlock requirement |
| --- | --- | --- |
| droplet | Baby form | Default |
| ripple | Teen form | 30-day streak + 5 sessions |
| tidal | Majestic adult | 90-day streak + resilience >= 80 |

`EvolutionStage.allCases` is ordered by `sortOrder`. `CharacterUnlock.canEvolve` and `.evolutionProgress` derive from `streakDays`, `sessionsCompleted`, and `resilienceScore` persisted on the `@Model`.

## Persistence

`CharacterUnlock` is a SwiftData `@Model` with a uniqueness constraint on `characterId`. Fields:

- `characterId`, `isUnlocked`, `currentEvolution` (stored as raw string), `isActive`
- `unlockedAt`, `lastEvolvedAt`
- `streakDays`, `sessionsCompleted`, `resilienceScore`

`StressMonitorApp.seedDefaultCharacterUnlocks(in:)` runs once at first launch: it inserts one `CharacterUnlock` row per `CharacterCreature`, marks free characters as unlocked, and sets Ripple as the active character. The active selection syncs to `CharacterSelectionSync` so the widget and watch can read it.

## Views

| View | File | Purpose |
| --- | --- | --- |
| `CharacterCollectionView` | `StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift` | Grid of all characters with lock state |
| `CharacterDetailView` | `StressMonitor/StressMonitor/Views/Characters/CharacterDetailView.swift` | Per-character evolution timeline, stats, unlock CTA |
| `CharacterPickerSheet` | `StressMonitor/StressMonitor/Views/Characters/CharacterPickerSheet.swift` | Switch active character |
| `EvolutionCelebrationView` | `StressMonitor/StressMonitor/Views/Characters/EvolutionCelebrationView.swift` | Celebration animation on stage change |
| `CharacterGridCard` | `StressMonitor/StressMonitor/Views/Characters/Components/CharacterGridCard.swift` | Cell in the collection grid |
| `EvolutionStageRow` | `StressMonitor/StressMonitor/Views/Characters/Components/EvolutionStageRow.swift` | Stage progress row |

The collection view moved from a top-level tab to Settings in the June 2026 redesign (commit `60518c4`). Premium characters gate behind `PaywallController.present(reason: .characters)`.

## Asset system

Characters are rendered from exported SVG assets in the Asset Catalog rather than procedural SwiftUI. The migration in commit `b99b1ca` replaced the procedural drawing code with `CharacterAssetCatalog` (at `StressMonitor/StressMonitor/Theme/CharacterAssetCatalog.swift`). `CharacterIllustrationExporter` (at `StressMonitor/StressMonitor/Services/CharacterIllustrationExporter.swift`) packages assets into ZIP exports for design review.

## Entry points for modification

- **Add a new character**: add a case to `CharacterCreature.allCharacters` with element, colors, and unlock type; add the asset to `CharacterAssetCatalog`; add a seeding row in `StressMonitorApp.seedDefaultCharacterUnlocks`.
- **Tune evolution requirements**: edit `CharacterUnlock.meetsRequirements(for:)` and `.evolutionProgress`.
- **Change the active-character sync target**: edit `CharacterSelectionSync` (referenced from `StressMonitorApp` and read by the widget extension).
