# Data models

The persisted and shared data shapes in StressMonitor.

## SwiftData @Model classes

### StressMeasurement

Central record. One row per stress calculation. Defined at `StressMonitor/StressMonitor/Models/StressMeasurement.swift`.

| Field | Type | Notes |
| --- | --- | --- |
| `timestamp` | `Date` | When the measurement was taken |
| `stressLevel` | `Double` | Composite 0-100 score |
| `hrv` | `Double` | Raw HRV (SDNN, ms) |
| `restingHeartRate` | `Double` | Resting heart rate |
| `categoryRawValue` | `String` | `StressCategory.rawValue` |
| `confidences` | `[Double]?` | Optional per-factor confidences |
| `hrvComponent` | `Double?` | Added in multi-factor migration |
| `hrComponent` | `Double?` | Added in multi-factor migration |
| `sleepComponent` | `Double?` | Added in multi-factor migration |
| `activityComponent` | `Double?` | Added in multi-factor migration |
| `recoveryComponent` | `Double?` | Added in multi-factor migration |
| `dataCompleteness` | `Double?` | 0-1 ratio of available weight |
| `isSynced` | `Bool` | CloudKit mirror confirmed |
| `cloudKitRecordName` | `String?` | CKRecord name |
| `deviceID` | `String` | Originating device |
| `cloudKitModTime` | `Date?` | Conflict resolution timestamp |

### CharacterUnlock

Character unlock state and evolution progress. Defined at `StressMonitor/StressMonitor/Models/Character/CharacterUnlock.swift`.

| Field | Type | Notes |
| --- | --- | --- |
| `characterId` | `String` | e.g. "ripple", "blossom" (unique) |
| `isUnlocked` | `Bool` | Whether the user owns this character |
| `currentEvolution` | `String` | `EvolutionStage.rawValue` |
| `isActive` | `Bool` | Currently selected character |
| `unlockedAt` | `Date?` | When unlocked |
| `lastEvolvedAt` | `Date?` | When last evolved |
| `streakDays` | `Int` | Streak toward evolution |
| `sessionsCompleted` | `Int` | Sessions toward evolution |
| `resilienceScore` | `Double` | Resilience metric |

### Habit

Habit tracking entry. Added in schema V2. Defined at `StressMonitor/StressMonitor/Models/Habit.swift`.

## CloudKit schema

Defined in `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSchema.swift`. The `StressMeasurement` record type maps each SwiftData field to a CKRecord field. Notable additions:

- `isDeleted`: soft-delete tombstone flag.
- `cloudKitModTime`: explicit modification timestamp used by `ConflictResolver`.
- `deviceID`: originating device identifier.

## WidgetSharedData

The compact snapshot written to the App Group for the widget extension and watch app. Defined at `StressMonitor/StressMonitor/Models/WidgetSharedData.swift`. Fields:

- Current stress level and category.
- Timestamp.
- Active character ID and evolution stage.
- Brief recent trend summary.

`WidgetDataProvider` (at `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift`) reads this from the App Group container and falls back to placeholder data in previews.

## Value types (not persisted)

These value types flow through the algorithm and UI but are not directly persisted as rows. Their values are folded into `StressMeasurement` fields when a measurement is saved.

- `StressContext`, `StressResult`, `FactorBreakdown`, `FactorWeights` - see [Stress context](../primitives/stress-context.md).
- `HRVMeasurement`, `HeartRateSample`, `SleepData`, `ActivityData`, `RecoveryData`, `PersonalBaseline` - see [Health models](../primitives/health-models.md).
- `ChatMessage`, `StressContextPayload` - see [Chat models](../primitives/chat-models.md).
- `BioAgeResult` - see [Bio age result](../primitives/bio-age-result.md).
- `SubscriptionPlan` - see [Subscription plan](../primitives/subscription-plan.md).
- `MoodEntry` at `StressMonitor/StressMonitor/Models/MoodEntry.swift`.
- `Habit` (model) and `HabitLog` value type.
