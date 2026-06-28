# By the numbers

Data collected on 2026-06-28. Figures are derived from the default branch (`main`) at commit `a4277ec`.

## Size

The codebase is ~54,000 lines of Swift across 390 source files. Three Xcode targets and one test bundle.

```mermaid
xychart-beta
    title "Lines of Swift by target"
    x-axis ["iOS app", "watchOS app", "Widget", "Tests"]
    y-axis "Lines of code" 0 --> 45000
    bar [41261, 4419, 1385, 756]
```

| Metric | Count |
| --- | --- |
| Swift source files | 390 |
| Total lines of Swift | ~54,300 |
| Unit test files | 5 (in `StressMonitorTests/`) |
| Test lines | 756 |
| Test-to-code ratio | ~1.4% (test suite is sparse, called out as B3 blocker) |

## Activity

The repository has 285 commits since the initial commit on 2026-01-18.

```mermaid
xychart-beta
    title "Commits per month (2026)"
    x-axis ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
    y-axis "Commits" 0 --> 150
    bar [27, 27, 35, 34, 19, 143]
```

June 2026 is the busiest month by a wide margin (143 commits), driven by the full UI redesign to the Ripple design system, the icon system migration, and the character SVG asset migration.

### Churn hotspots (last 90 days)

| File | Changes |
| --- | --- |
| `StressMonitor/StressMonitor/Views/DashboardView.swift` | 15 |
| `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` | 14 |
| `StressMonitor/StressMonitor/Views/Trends/TrendsView.swift` | 11 |
| `StressMonitor/StressMonitor/Views/Action/ActionView.swift` | 10 |
| `StressMonitor/StressMonitorWidget/Views/MediumWidgetView.swift` | 8 |
| `StressMonitor/StressMonitor/ViewModels/ChatViewModel.swift` | 8 |
| `StressMonitor/StressMonitorWidget/Views/LargeWidgetView.swift` | 7 |
| `StressMonitor/StressMonitor/Views/MainTabView.swift` | 7 |
| `StressMonitor/StressMonitor/Views/Characters/CharacterCollectionView.swift` | 7 |
| `StressMonitor/StressMonitor/Views/Onboarding/OnboardingSuccessView.swift` | 6 |

The dashboard, settings, and trends views are the most churned files, reflecting the June redesign pass.

## Bot-attributed commits

Zero commits in the default branch history carry a bot co-author signature (`Co-authored-by: factory-droid[bot]`, `dependabot[bot]`, `github-actions[bot]`, `copilot[bot]`). This is a lower bound on AI-assisted work; inline AI tools like Copilot leave no trace in git history.

## Complexity

### Largest source files

| File | Lines |
| --- | --- |
| `StressMonitor/Views/StressHistoryView.swift` (legacy) | 840 |
| `StressMonitor/StressMonitor/Components/Character/RippleCharacterView.swift` | 573 |
| `StressMonitor/StressMonitor/ViewModels/StressViewModel.swift` | 571 |
| `StressMonitor/StressMonitor/Components/Character/BlossomCharacterView.swift` | 552 |
| `StressMonitor/StressMonitor/Views/Trends/TrendsViewModel.swift` | 550 |
| `StressMonitor/StressMonitor/Components/Character/EmberCharacterView.swift` | 539 |
| `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift` | 537 |
| `StressMonitor/StressMonitor/Components/Character/LumiCharacterView.swift` | 533 |
| `StressMonitor/StressMonitor/Components/Character/ZephyrCharacterView.swift` | 532 |
| `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift` | 509 |

The five `*CharacterView.swift` files in `Components/Character/` are procedural SwiftUI drawing code that was replaced by exported SVG assets in commit `b99b1ca`. The largest actively-used source files are `StressViewModel.swift`, `TrendsViewModel.swift`, and `CloudKitResetService.swift`.

### Unique contributors

Six distinct author names appear in git history on the default branch, all aliases of the same developer (`ddx-pro17`, `Phuong Doan`, `phuongddx`, `PhuongDoan`, `phuongdoan-muji-aavn`, `phuongdoanx`). Bus factor is effectively one.
