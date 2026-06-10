# Implementation Plan: [P1] Write Unit Tests — ViewModels

**Task ID:** t_c765090f  
**Branch:** `test/viewmodels`  
**Date:** 2025-06-10  
**Priority:** P1  

---

## 1. Overview

Write comprehensive unit tests for the ViewModel layer of the StressMonitor iOS app. The primary target is `StressViewModel` — the app's central ViewModel that orchestrates health data fetching, stress calculation, and dashboard state. Secondary targets include `PremiumViewModel` and `BreathingSessionViewModel`, which have simpler but testable state machines.

**Scope note:** `DashboardViewModel` is dead code (no instantiation sites) and should be deleted in a prerequisite task (t_151af85e) before this work begins. `HistoryViewModel` and `SettingsViewModel` take a `ModelContext` in their initializer, making them harder to unit-test without SwiftData infrastructure — they are out of scope for this task.

---

## 2. Architecture Context

### 2.1 StressViewModel Dependency Graph

```
StressViewModel
├── healthKit: HealthKitServiceProtocol     ← mockable
├── algorithm: StressAlgorithmServiceProtocol ← mockable
├── repository: StressRepositoryProtocol     ← mockable
├── calibrator: FactorCalibrator             ← internal, deterministic
├── healthStore: HKHealthStore               ← real, used for observer query
├── InsightGenerator                         ← static enum, no state
└── HapticManager.shared                     ← singleton, fire-and-forget
```

All three protocol dependencies are already abstracted behind protocols with existing mock implementations in `MockServices.swift`:
- `MockHealthKitService` — configurable `mockHRV`, `mockHeartRate`, `shouldThrowError`, etc.
- `MockStressAlgorithmService` — configurable `mockStressLevel`, `mockConfidence`
- `MockStressRepository` — in-memory `mockMeasurements`, `mockBaseline`

### 2.2 Key Models

| Model | Key Fields |
|---|---|
| `StressResult` | `level: Double`, `category: StressCategory`, `confidence`, `hrv`, `heartRate`, `factorBreakdown: FactorBreakdown?` |
| `StressMeasurement` | `@Model` class — `stressLevel`, `hrv`, `restingHeartRate`, `timestamp`, multi-factor components |
| `HRVMeasurement` | `value: Double`, `timestamp: Date` |
| `HeartRateSample` | `value: Double`, `timestamp: Date` |
| `PersonalBaseline` | `restingHeartRate`, `baselineHRV`, `factorWeights`, `calibrationDate` |
| `StressContext` | `baseline`, `hrv`, `heartRate`, `sleepData`, `activityData`, `recoveryData` |
| `DataQualityInfo` | `activeFactors`, `missingFactors`, `dataCompleteness` |
| `AIInsight` | `title`, `message`, `actionTitle`, `trendData` |
| `FactorBreakdown` | `hrvComponent`, `hrComponent`, `sleepComponent`, `activityComponent`, `recoveryComponent`, `dataCompleteness` |

### 2.3 StressViewModel Public API Surface

| Method | Purpose | State Effects |
|---|---|---|
| `loadCurrentStress()` | Fetch HRV + HR → calculate stress | Sets `isLoading`, `currentStress`, `errorMessage`, `isPermissionRequired`, `baseline`, `lastRefresh`, `dataQualityInfo` |
| `requestHealthKitAccess()` | Request HK auth, then load stress | Sets `isRequestingAccess`, `isPermissionRequired`, `errorMessage` |
| `loadHistoricalData(days:)` | Fetch recent measurements | Sets `isLoading`, `historicalData`, `errorMessage` |
| `loadBaseline()` | Load + optionally calibrate baseline | Sets `isLoading`, `baseline`, `dataQualityInfo`, `errorMessage` |
| `refreshHealthData()` | Alias for `loadCurrentStress()` | Same as `loadCurrentStress()` |
| `calculateAndSaveStress()` | Calculate + persist to repository | Throws `StressError.noData`, sets `currentStress`, `lastRefresh` |
| `clearError()` | Clear error message | Sets `errorMessage = nil` |
| `loadDashboardData()` | Load stress + history + today + weekly + insight | Combines multiple loads |
| `loadTodayMeasurements()` | Filter today from historical | Sets `todayMeasurements`, `hrvHistory` |
| `loadWeeklyComparison()` | Current vs previous week averages | Sets `weeklyCurrentAvg`, `weeklyPreviousAvg` |
| `generateInsight()` | AI insight from current stress | Sets `aiInsight` |
| `observeHeartRate()` | Subscribe to live HR stream | Sets `liveHeartRate` |
| `startAutoRefresh()` | Begin HK observer (no-op on simulator) | Starts background task |
| `stopAutoRefresh()` | Cancel observer + tasks | Cleans up |

### 2.4 Error Handling Patterns in StressViewModel

1. **HealthKit auth denied** (`HKError.errorAuthorizationDenied`): Sets `isPermissionRequired = true`, `currentStress = nil`
2. **HealthKit auth not determined** (`HKError.errorAuthorizationNotDetermined`): Sets `isPermissionRequired = true` (in `requestHealthKitAccess`)
3. **No HRV data**: Sets `errorMessage = "No HRV data available"`
4. **Generic errors**: Sets `errorMessage = error.localizedDescription`
5. **calculateAndSaveStress throws**: Propagates `StressError.noData` if HRV is nil

---

## 3. Test Plan

### 3.0 Prerequisite: Delete DashboardViewModel

- **Action:** Delete `StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift`
- **Reference:** Task t_151af85e
- **Reason:** Dead code — no instantiation sites found anywhere. `StressViewModel` handles all dashboard logic.
- **Note:** The file also defines `TrendDirection` enum at file scope. Verify this isn't imported elsewhere; if needed, relocate to a shared location before deleting. (StressViewModel already defines its own nested `TrendDirection`.)

### 3.1 Test Infrastructure

#### File: `StressMonitorTests/ViewModelTestHelpers.swift`

Create shared test helper utilities:

```swift
// Common factory methods for test data:
// - makeStressResult(level:category:) — convenience StressResult constructor
// - makeStressMeasurement(stressLevel:hrv:hoursAgo:) — timestamped test measurement
// - makeHistoricalData(count:days:) — generate N days of test measurements
// - makeFactorBreakdown(...) — with configurable components
//
// Mock enhancements (extend existing MockHealthKitService etc.):
// - MockHealthKitService with specific error throwing (HKError, custom)
// - MockStressAlgorithmService with factorBreakdown support
//   (current mock doesn't set factorBreakdown on StressResult)
```

**Key insight:** The existing `MockStressAlgorithmService` does NOT populate `factorBreakdown` in its `calculateStress` method. We need to add a `calculateMultiFactorStress` override that returns results with `factorBreakdown` to test the `dataQualityInfo` code path in `loadCurrentStress`.

### 3.2 StressViewModel Tests

#### File: `StressMonitorTests/StressViewModelTests.swift`

All tests use `XCTest` and `@MainActor` (since `StressViewModel` is `@MainActor`).

#### 3.2.1 Initialization Tests

| Test | What It Verifies |
|---|---|
| `testInitialState` | All properties default: `currentStress == nil`, `historicalData.isEmpty`, `isLoading == false`, `errorMessage == nil`, `isPermissionRequired == false`, `isRequestingAccess == false`, `liveHeartRate == nil`, `hrvHistory.isEmpty`, `todayMeasurements.isEmpty`, `weeklyCurrentAvg == 0`, `weeklyPreviousAvg == 0`, `aiInsight == nil`, `dataQualityInfo == nil`, `lastRefresh == nil` |

#### 3.2.2 loadCurrentStress — Happy Path

| Test | What It Verifies |
|---|---|
| `testLoadCurrentStress_Success` | Mock returns HRV=50, HR=72. Verifies `currentStress` set with correct level/category, `isLoading` transitions false→true→false, `lastRefresh` set, `errorMessage == nil`, `isPermissionRequired == false` |
| `testLoadCurrentStress_SetsBaselineFromRepository` | Repository returns a specific baseline; verify `baseline` is populated |
| `testLoadCurrentStress_UsesExistingBaselineIfSet` | Set `baseline` before call; repository also returns one. Verify the VM's existing baseline takes precedence |
| `testLoadCurrentStress_SetsDataQualityInfo` | Mock algorithm returns result with `factorBreakdown`; verify `dataQualityInfo` is populated with correct active/missing factors |

#### 3.2.3 loadCurrentStress — Error Paths

| Test | What It Verifies |
|---|---|
| `testLoadCurrentStress_NoHRVData` | Mock returns `nil` for HRV. Verify `errorMessage == "No HRV data available"`, `currentStress == nil` |
| `testLoadCurrentStress_HealthKitThrowsGeneric` | Mock throws `NSError`. Verify `errorMessage` set, `isLoading == false` (defer recovery) |
| `testLoadCurrentStress_AuthDenied` | Mock throws `HKError(.errorAuthorizationDenied)`. Verify `isPermissionRequired == true`, `currentStress == nil` |
| `testLoadCurrentStress_ClearsPreviousErrorOnSuccess` | Set `errorMessage` to something, then load successfully. Verify `errorMessage == nil` |

#### 3.2.4 requestHealthKitAccess

| Test | What It Verifies |
|---|---|
| `testRequestHealthKitAccess_Success` | Mock succeeds. Verify `isPermissionRequired == false`, then `currentStress` loaded |
| `testRequestHealthKitAccess_AuthDenied` | Mock throws `HKError(.errorAuthorizationDenied)`. Verify `isPermissionRequired == true` |
| `testRequestHealthKitAccess_AuthNotDetermined` | Mock throws `HKError(.errorAuthorizationNotDetermined)`. Verify `isPermissionRequired == true` |
| `testRequestHealthKitAccess_GenericError` | Mock throws generic error. Verify `errorMessage` set |
| `testRequestHealthKitAccess_GuardsDoubleTap` | Call twice rapidly. Second call should be no-op (isRequestingAccess guard). Verify only one auth request made |
| `testRequestHealthKitAccess_ResetAfterCompletion` | After successful call, verify `isRequestingAccess == false` (defer cleanup) |

#### 3.2.5 loadHistoricalData

| Test | What It Verifies |
|---|---|
| `testLoadHistoricalData_Success` | Repository returns measurements. Verify `historicalData` populated |
| `testLoadHistoricalData_UsesCorrectLimit` | `loadHistoricalData(days: 7)` should call `fetchRecent(limit: 7*24)` |
| `testLoadHistoricalData_Error` | Repository throws. Verify `errorMessage` set, `historicalData` unchanged |
| `testLoadHistoricalData_ClearsErrorOnSuccess` | Pre-set error, then load succeeds. Verify `errorMessage == nil` |

#### 3.2.6 loadBaseline

| Test | What It Verifies |
|---|---|
| `testLoadBaseline_Success_NoCalibration` | <30 measurements. Verify baseline loaded, no calibration triggered |
| `testLoadBaseline_Success_WithCalibration` | ≥30 measurements with component data. Verify `calibrationDate` set on baseline, `factorWeights` updated |
| `testLoadBaseline_Error` | Repository throws. Verify `errorMessage` set |
| `testLoadBaseline_UpdatesDataQualityInfo` | If `currentStress` has factorBreakdown, verify `dataQualityInfo` refreshed with new baseline |

#### 3.2.7 calculateAndSaveStress

| Test | What It Verifies |
|---|---|
| `testCalculateAndSaveStress_Success` | Verify `StressMeasurement` saved to repository with correct fields, `currentStress` set |
| `testCalculateAndSaveStress_ThrowsNoData` | HRV returns nil. Verify throws `StressError.noData` |
| `testCalculateAndSaveStress_PopulatesFactorComponents` | Result has factorBreakdown; verify measurement's `hrvComponent`, `hrComponent`, etc. are set |

#### 3.2.8 clearError

| Test | What It Verifies |
|---|---|
| `testClearError` | Set `errorMessage`, call `clearError()`, verify nil |

#### 3.2.9 Dashboard Data Methods

| Test | What It Verifies |
|---|---|
| `testLoadDashboardData` | Verify calls all sub-methods; `currentStress` + `historicalData` populated |
| `testLoadTodayMeasurements` | Populate `historicalData` with mixed dates; verify `todayMeasurements` filtered to today only |
| `testLoadTodayMeasurements_SetsHRVHistory` | Verify `hrvHistory` contains last 7 HRV values from today's measurements |
| `testLoadWeeklyComparison_CurrentWeekOnly` | Only current week data. Verify `weeklyCurrentAvg` correct, `weeklyPreviousAvg == 0` |
| `testLoadWeeklyComparison_BothWeeks` | Data in both weeks. Verify both averages calculated correctly |
| `testLoadWeeklyComparison_EmptyData` | No data. Both averages 0 |
| `testGenerateInsight_HighStress` | Stress > 75. Verify `aiInsight` not nil |
| `testGenerateInsight_NoCurrentStress` | `currentStress == nil`. Verify `aiInsight == nil` |

#### 3.2.10 Heart Rate Observation

| Test | What It Verifies |
|---|---|
| `testObserveHeartRate_UpdatesLiveHeartRate` | Use mock `AsyncStream` that yields a value. Verify `liveHeartRate` updated |
| `testObserveHeartRate_Cancellable` | Start observation, verify task exists (indirectly — call `stopAutoRefresh` and verify no crash) |

#### 3.2.11 Auto-Refresh

| Test | What It Verifies |
|---|---|
| `testStopAutoRefresh_CleansUp` | Call `stopAutoRefresh()`. Verify no crash (indirect cleanup) |
| `testStartAutoRefresh_OnSimulator` | Should be no-op on simulator (`#if targetEnvironment(simulator)` guard). Verify no crash |

**Note:** `startAutoRefresh()` uses `#if targetEnvironment(simulator)` and `#if DEBUG` with `DemoMode`. In the test target running on simulator, the method effectively returns early. Full testing of the HKObserverQuery path would require a device test or extracting the observer setup into a testable protocol.

#### 3.2.12 Loading State Transitions

| Test | What It Verifies |
|---|---|
| `testLoadCurrentStress_LoadingStateTransitions` | Verify `isLoading` is `false` before, and `false` after (using `defer`). Note: `isLoading` is set to `true` at start and `false` in `defer`, so it's `false` by the time the async method returns to the caller. We can verify the end state. |
| `testLoadHistoricalData_LoadingStateTransitions` | Same pattern |

---

### 3.3 PremiumViewModel Tests

#### File: `StressMonitorTests/PremiumViewModelTests.swift`

| Test | What It Verifies |
|---|---|
| `testInitialState` | `isLoading == false`, `showError == false`, `showSuccess == false`, `errorMessage == nil`, `plans.isEmpty` |
| `testLoadInitialData` | Mock returns plans. Verify `plans` populated |
| `testPurchaseSelectedPlan_Success` | Purchase succeeds. Verify `premiumState.isPremiumUser == true`, `showSuccess == true` |
| `testPurchaseSelectedPlan_NoPlanSelected` | `selectedPlanDetails == nil`. Verify error state set |
| `testPurchaseSelectedPlan_Cancelled` | `StoreKitError.purchaseCancelled`. Verify silent (no error shown) |
| `testPurchaseSelectedPlan_Error` | Generic error. Verify `showError == true`, `errorMessage` set |
| `testRestorePurchases_Success` | Restore succeeds, premium user. Verify `showSuccess == true` |
| `testRestorePurchases_Error` | Error. Verify error state |
| `testDismissError` | Clears `showError` and `errorMessage` |

**Prerequisites:** `StoreKitServiceProtocol` and `PremiumState` must be importable. Verify they're in the main target and accessible via `@testable import`.

### 3.4 BreathingSessionViewModel Tests

#### File: `StressMonitorTests/BreathingSessionViewModelTests.swift`

| Test | What It Verifies |
|---|---|
| `testInitialState` | `sessionDuration == 120`, `remainingTime == 120`, `breathingPhase == .inhale`, `isActive == false`, `sessionResult == nil` |
| `testStartSession_SetsActive` | Verify `isActive == true`, `remainingTime == sessionDuration` |
| `testEndSession_SetsInactive` | Verify `isActive == false` after end |

**Note:** `BreathingSessionViewModel` uses `Timer` and `DispatchQueue.main.asyncAfter`, making it harder to test timing-based behavior in unit tests. Focus on state transitions that are synchronously testable.

---

## 4. Mock Enhancements Needed

### 4.1 MockHealthKitService — Error Simulation

Add to existing mock or create a test-specific subclass:

```swift
// Add property:
var authError: Error?

// Override requestAuthorization:
func requestAuthorization() async throws {
    if let error = authError { throw error }
    if shouldThrowError { throw NSError(domain: "Mock", code: -1) }
}
```

### 4.2 MockStressAlgorithmService — Factor Breakdown Support

The current mock's `calculateStress` doesn't set `factorBreakdown`. Add:

```swift
var mockFactorBreakdown: FactorBreakdown?

// Override calculateMultiFactorStress:
func calculateMultiFactorStress(context: StressContext) async throws -> StressResult {
    StressResult(
        level: mockStressLevel,
        category: StressCategory(from: mockStressLevel),
        confidence: mockConfidence,
        hrv: context.hrv ?? 50,
        heartRate: context.heartRate ?? 72,
        factorBreakdown: mockFactorBreakdown
    )
}
```

### 4.3 MockHealthKitService — Heart Rate Stream Control

For testing `observeHeartRate()`:

```swift
var heartRateContinuation: AsyncStream<HeartRateSample?>.Continuation?

func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
    AsyncStream { continuation in
        self.heartRateContinuation = continuation
    }
}
```

This lets tests push values and verify `liveHeartRate` updates.

### 4.4 HKError Construction Helper

To test auth-denied paths, we need to construct `HKError` instances:

```swift
static func makeHKAuthDeniedError() -> HKError {
    HKError(.errorAuthorizationDenied)
}
```

---

## 5. Test File Structure

```
StressMonitorTests/
├── ViewModelTestHelpers.swift          ← Shared factories, mock enhancements
├── StressViewModelTests.swift          ← ~30 test methods
├── PremiumViewModelTests.swift         ← ~9 test methods
├── BreathingSessionViewModelTests.swift ← ~3 test methods
├── (existing test files unchanged)
```

---

## 6. Implementation Order

### Phase 1: Setup (Branch + Infrastructure)
1. Create branch `test/viewmodels` from `main`
2. Delete `DashboardViewModel.swift` (prerequisite t_151af85e)
3. Create `StressMonitorTests/ViewModelTestHelpers.swift` with test factories and mock enhancements
4. Verify the test target compiles with the new file added to the Xcode project

### Phase 2: StressViewModel Core Tests
5. Write initialization tests (1 test)
6. Write `loadCurrentStress` happy-path tests (4 tests)
7. Write `loadCurrentStress` error-path tests (4 tests)
8. Write `requestHealthKitAccess` tests (6 tests)
9. Write `loadHistoricalData` tests (4 tests)
10. Write `loadBaseline` tests (4 tests)
11. Write `calculateAndSaveStress` tests (3 tests)
12. Write `clearError` test (1 test)

### Phase 3: StressViewModel Dashboard Tests
13. Write dashboard data method tests (9 tests)
14. Write heart rate observation tests (2 tests)
15. Write auto-refresh tests (2 tests)
16. Write loading state transition tests (2 tests)

### Phase 4: Secondary ViewModels
17. Write `PremiumViewModel` tests (9 tests)
18. Write `BreathingSessionViewModel` tests (3 tests)

### Phase 5: Verification
19. Run full test suite: `xcode_test(scheme: "StressMonitor")`
20. Verify all new tests pass; fix any failures
21. Verify no regressions in existing tests
22. Commit and create PR

---

## 7. Estimated Test Count

| Category | Tests |
|---|---|
| StressViewModel — Init | 1 |
| StressViewModel — loadCurrentStress | 8 |
| StressViewModel — requestHealthKitAccess | 6 |
| StressViewModel — loadHistoricalData | 4 |
| StressViewModel — loadBaseline | 4 |
| StressViewModel — calculateAndSaveStress | 3 |
| StressViewModel — clearError | 1 |
| StressViewModel — Dashboard methods | 9 |
| StressViewModel — Heart rate + auto-refresh | 4 |
| StressViewModel — Loading states | 2 |
| PremiumViewModel | 9 |
| BreathingSessionViewModel | 3 |
| **Total** | **~54 tests** |

---

## 8. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| `@MainActor` on StressViewModel requires `await` in tests | Use `await` in all test methods; XCTest supports async tests natively |
| `HKError` construction requires HealthKit import | Import HealthKit in test file; `HKError(.errorAuthorizationDenied)` works in test target |
| `StressMeasurement` is a `@Model` class (SwiftData) | It can be instantiated without a ModelContext for simple data creation (used in existing tests) |
| `startAutoRefresh()` no-ops on simulator | Don't try to test the HKObserverQuery path; test `stopAutoRefresh()` for cleanup only |
| `DemoMode.isEnabled` is compile-time + launch-arg gated | No testing needed — it's `#if DEBUG` + ProcessInfo check |
| `TrendDirection` defined in both DashboardViewModel and StressViewModel | After deleting DashboardViewModel, only StressViewModel's nested enum remains. Verify no compile errors |
| Mock services are `@unchecked Sendable` | This is fine for tests — they run on main actor and aren't shared across isolation boundaries |
| `FactorCalibrator` is a concrete dependency (not mocked) | It's deterministic and pure — test with known inputs; no need to mock |

---

## 9. Notes for Implementation

- All test classes should follow the existing pattern: `import XCTest`, `@testable import StressMonitor`, class inherits `XCTestCase`
- Use `XCTAssertEqual`, `XCTAssertNil`, `XCTAssertNotNil`, `XCTAssertTrue/False` as appropriate
- Use `XCTAssertEqual(_:accuracy:)` for floating-point comparisons
- Group tests with `// MARK:` sections matching the method under test
- Test method naming: `testMethodName_Scenario_ExpectedBehavior` (e.g., `testLoadCurrentStress_AuthDenied_SetsPermissionRequired`)
- Each test should be independent — use `setUp()` to create fresh mocks and VM instances
- Keep tests focused: one assertion concept per test, even if multiple XCTAssert calls are needed
