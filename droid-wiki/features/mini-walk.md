# Mini Walk

A short walking exercise with a circular countdown timer. Designed as a low-friction stress relief action alongside breathing. Lives under the Action tab and is reachable from the dashboard quick-action grid.

## Views

| View | File | Purpose |
| --- | --- | --- |
| `MiniWalkView` | `StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkView.swift` | Setup and active session |
| `MiniWalkCompleteView` | `StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkCompleteView.swift` | Completion summary |
| `MiniWalkViewModel` | `StressMonitor/StressMonitor/Views/MiniWalk/MiniWalkViewModel.swift` | Session state machine |
| `Components/` | `StressMonitor/StressMonitor/Views/MiniWalk/Components/` | Circular timer, step counter |

## Session

The view model drives a circular countdown timer (default duration configurable in the setup screen). During the walk it displays elapsed time, step count (from `CMPedometer` or HealthKit), and a Ripple character companion. On completion it shows a summary card with duration, steps, and a stress-score delta if a post-walk HRV reading is available.

The Mini Walk redesign in commit `d80d8a9` introduced the Ripple character system into the walking screens to match the breathing flow.

## Entry points for modification

- **Change default walk duration**: edit `MiniWalkViewModel` initial state.
- **Change the completion metrics**: edit `MiniWalkCompleteView.swift` and the post-session HealthKit fetch in `MiniWalkViewModel`.
