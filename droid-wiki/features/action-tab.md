# Action tab

The second tab. Aggregates immediate stress-relief actions (breathing, mini walk), habit tracking, and personalized recommendations. Redesigned in June 2026 (commit `0f14405`) as a six-section layout per the `05-action.html` design spec.

## Views

| View | File | Purpose |
| --- | --- | --- |
| `ActionView` | `StressMonitor/StressMonitor/Views/Action/ActionView.swift` | Root for the Action tab |
| `ActionGroupRow` | `StressMonitor/StressMonitor/Views/Action/Components/ActionGroupRow.swift` | Section header row for an action group |
| `RippleRecommendationCard` | `StressMonitor/StressMonitor/Views/Action/Components/RippleRecommendationCard.swift` | Personalized recommendation card |
| `HabitLogRow` | `StressMonitor/StressMonitor/Views/Action/Components/HabitLogRow.swift` | Habit log entry row |

## Habit tracking

Habits are persisted through the `Habit` `@Model` added in schema V2. `HabitViewModel` (at `StressMonitor/StressMonitor/ViewModels/HabitViewModel.swift`) owns the create / log / streak logic. Each habit tracks daily completion and a rolling streak; the Action tab surfaces today's habits and lets the user log completion with a single tap.

The habit model lives at `StressMonitor/StressMonitor/Models/Habit.swift`. Habit completion does not directly affect the stress score, but sustained habit streaks feed into the character evolution progress through `CharacterUnlock.streakDays`.

## Recommendations

`RippleRecommendationCard` surfaces context-aware suggestions based on the current stress category and time of day. The recommendation engine is driven by `InsightGeneratorService` (at `StressMonitor/StressMonitor/Services/InsightGeneratorService.swift`), which produces short textual nudges ("Try a 4-7-8 breathing pattern", "Take a 5-minute walk") without invoking the LLM.

## Entry points for modification

- **Add a new action group**: add a row in `ActionView` and a destination route in `Route.swift`.
- **Add a new habit type**: extend the `Habit` model and add creation UI in `HabitViewModel`.
- **Tune recommendations**: edit `InsightGeneratorService.swift`.
