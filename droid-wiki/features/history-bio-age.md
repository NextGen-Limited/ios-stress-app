# History and bio age

Measurement history list, detail view, and the biological age deep-dive. Reachable from the Trends tab and through deep links.

## History views

| View | File | Purpose |
| --- | --- | --- |
| `MeasurementHistoryView` | `StressMonitor/StressMonitor/Views/History/MeasurementHistoryView.swift` | Scrollable list of past measurements with filters |
| `MeasurementDetailView` | `StressMonitor/StressMonitor/Views/History/MeasurementDetailView.swift` | Single measurement detail: factor breakdown, raw values |
| `HistoryViewModel` | `StressMonitor/StressMonitor/Views/History/HistoryViewModel.swift` | List state, filtering, pagination |
| `DetailViewModel` | `StressMonitor/StressMonitor/Views/History/DetailViewModel.swift` | Single-measurement loading |
| `BioAgeDetailView` | `StressMonitor/StressMonitor/Views/History/BioAgeDetailView.swift` | Bio age deep-dive (premium) |
| `History/Components/` | `StressMonitor/StressMonitor/Views/History/Components/` | Supporting components |

## Measurement detail

`MeasurementDetailView` shows the composite stress level, category, confidence, raw HRV and HR, and each factor's 0-1 contribution from `FactorBreakdown`. A timeline of factor values helps the user understand which signal drove the score.

## Bio age

`BioAgeDetailView` (premium) is a deep-dive into the biological age estimate produced by `BioAgeCalculator`. It shows the estimated bio age, the chronological age (from HealthKit date of birth), the delta, and the per-signal contributions (HRV-vs-age-expected, resting HR-vs-age-expected, recovery trend). Selecting this view triggers `paywall.present(reason: .bioAgeDetail)` for non-premium users.

`BioAgeResult` (at `StressMonitor/StressMonitor/Models/BioAgeResult.swift`) is the model returned by `BioAgeCalculator`. Fields include the estimated age, confidence, per-factor contributions, and the input window.

## Entry points for modification

- **Extend measurement detail**: edit `MeasurementDetailView.swift` and add fields to `DetailViewModel`.
- **Tune bio age calculation**: edit `BioAgeCalculator` at `StressMonitor/StressMonitor/Services/Algorithm/BioAgeCalculator.swift`. Tests at `StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift` pin the expected outputs.
