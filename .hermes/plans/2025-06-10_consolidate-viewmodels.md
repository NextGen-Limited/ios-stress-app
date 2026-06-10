# [P1] Consolidate Duplicate ViewModels — Implementation Plan

**Task ID:** t_151af85e  
**Branch:** `refactor/consolidate-viewmodels`  
**Date:** 2025-06-10  
**Priority:** P1  
**Scope:** Merge `DashboardViewModel` into `StressViewModel`; delete dead code  

---

## 1. Executive Summary

Two ViewModels — `DashboardViewModel` (130 LOC, in `Views/Dashboard/`) and `StressViewModel` (407 LOC, in `ViewModels/`) — share ~80% code overlap. The live app already uses **only `StressViewModel`** for `DashboardView`. `DashboardViewModel` is dead code: no Swift source instantiates the class, and the `TrendDirection` enum it declares at file scope shadows the nested one in `StressViewModel`.

**Goal:** Delete `DashboardViewModel.swift` entirely and verify that no functionality is lost. This is a pure deletion refactor — no migration needed because the canonical ViewModel is already in place.

---

## 2. Detailed Analysis

### 2.1 DashboardViewModel (`Views/Dashboard/DashboardViewModel.swift`)

| Aspect | Detail |
|--------|--------|
| **Type** | `@Observable @MainActor class` (not `final`) |
| **Properties** | `currentStress`, `todayHRV`, `weeklyTrend`, `baseline`, `aiInsight`, `lastUpdated`, `isMeasuring`, `errorMessage`, `weeklyMeasurements` |
| **Dependencies** | `HealthKitServiceProtocol`, `StressAlgorithmServiceProtocol`, `StressRepositoryProtocol` (same init signature as StressViewModel) |
| **Key Methods** | `refreshStressLevel()`, `measureNow()`, `calculateTrend(from:)`, `generateInsight()` |
| **Algorithm** | Uses **2-factor** `algorithm.calculateStress(hrv:heartRate:)` — **outdated**; StressViewModel uses 5-factor `calculateMultiFactorStress(context:)` |
| **TrendDirection** | Top-level enum: `case up / down / stable` |
| **Used in production?** | **No.** Zero call-sites construct `DashboardViewModel`. |

### 2.2 StressViewModel (`ViewModels/StressViewModel.swift`)

| Aspect | Detail |
|--------|--------|
| **Type** | `@Observable @MainActor final class` |
| **Properties** | All of DashboardViewModel's + `historicalData`, `liveHeartRate`, `hrvHistory`, `heartRateTrend`, `todayMeasurements`, `weeklyCurrentAvg`, `weeklyPreviousAvg`, `dataQualityInfo`, `isPermissionRequired`, `isRequestingAccess`, plus auto-refresh infrastructure |
| **Dependencies** | Same three protocols + `FactorCalibrator` + `HKHealthStore` |
| **Key Methods** | `loadCurrentStress()`, `loadHistoricalData(days:)`, `loadBaseline()`, `calculateAndSaveStress()`, `observeHeartRate()`, `startAutoRefresh()`, `stopAutoRefresh()`, `loadDashboardData()`, `loadTodayMeasurements()`, `loadWeeklyComparison()`, `generateInsight()`, `requestHealthKitAccess()` |
| **Algorithm** | **5-factor** `calculateMultiFactorStress(context:)` with graceful degradation |
| **TrendDirection** | Nested enum: `StressViewModel.TrendDirection` |
| **Used in production?** | **Yes.** `DashboardView` directly uses `StressViewModel`. |

### 2.3 Call-Site Inventory

| File | Uses | Notes |
|------|------|-------|
| `Views/DashboardView.swift` | `StressViewModel` | `@State private var viewModel: StressViewModel` — lines 7, 13-28 |
| `Views/MainTabView.swift` | `StressViewModel` | Creates for `.home` tab — line 53 |
| `Services/MockServices.swift` | `StressViewModel` | `mockDashboardViewModel()` returns `StressViewModel` — line 269 |
| `Views/Dashboard/DashboardViewModel.swift` | `DashboardViewModel` | Only the class declaration itself — **zero consumers** |

### 2.4 Overlap Matrix

| Capability | DashboardViewModel | StressViewModel | Status |
|------------|-------------------|-----------------|--------|
| Fetch HRV + HR | ✅ `refreshStressLevel()` | ✅ `loadCurrentStress()` | Duplicated |
| Calculate stress | ✅ 2-factor (outdated) | ✅ 5-factor (current) | DVM is stale |
| Save measurement | ✅ in `refreshStressLevel()` | ✅ in `calculateAndSaveStress()` | Duplicated |
| Weekly measurements | ✅ `weeklyMeasurements` | ✅ via `historicalData` + `loadDashboardData()` | Duplicated |
| Trend calculation | ✅ `calculateTrend()` | ✅ `heartRateTrend` + `loadWeeklyComparison()` | Duplicated |
| AI insight generation | ✅ `generateInsight()` (hardcoded) | ✅ `generateInsight()` → `InsightGenerator` | DVM is simpler/stale |
| Baseline loading | ✅ inline in refresh | ✅ `loadBaseline()` with calibration | DVM is simpler |
| Auto-refresh | ❌ | ✅ HKObserverQuery + demo timer | DVM missing |
| Heart rate observation | ❌ | ✅ `observeHeartRate()` | DVM missing |
| Permission handling | ❌ | ✅ `requestHealthKitAccess()` | DVM missing |
| Historical data | ❌ | ✅ `loadHistoricalData()` | DVM missing |
| Data quality info | ❌ | ✅ `dataQualityInfo` | DVM missing |
| Error clearing | ❌ | ✅ `clearError()` | DVM missing |

**Conclusion:** `DashboardViewModel` is a strict subset (older, less capable version) of `StressViewModel`. It has zero production consumers and its algorithm is outdated. Safe to delete.

---

## 3. Implementation Plan

### Phase 1: Preparation (5 min)

**Step 1.1 — Create branch**
```bash
cd ~/Projects/ios-stress-app
git checkout main
git pull
git checkout -b refactor/consolidate-viewmodels
```

**Step 1.2 — Verify current build is green**
```bash
# Build via xcodebuild to ensure baseline compiles
xcodebuild build -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | tail -5
```

### Phase 2: Delete DashboardViewModel (10 min)

**Step 2.1 — Delete the file**
```bash
git rm StressMonitor/StressMonitor/Views/Dashboard/DashboardViewModel.swift
```

**Step 2.2 — Verify compilation**
```bash
xcodebuild build -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | tail -20
```

Since no source file references `DashboardViewModel` as a type (confirmed via grep), this deletion should compile cleanly with zero changes required elsewhere.

### Phase 3: Handle TrendDirection Collision (5 min)

**Current state:**
- `DashboardViewModel.swift` declares a **top-level** `enum TrendDirection` (line 126)
- `StressViewModel.swift` declares a **nested** `StressViewModel.TrendDirection` (line 53)
- `WeeklyInsightCard.swift` has its own **private** `TrendDirection` (line 101)

**After deletion of DashboardViewModel.swift:**
- The top-level `TrendDirection` will be removed
- `StressViewModel.TrendDirection` will be the sole production enum
- `WeeklyInsightCard`'s private enum is independent (different cases: `improved`/`increased`)

**Verify:** Any file referencing the top-level `TrendDirection` (without qualification) still compiles. Based on the search results, usage appears to go through `StressViewModel.TrendDirection` or is fully qualified, so no changes expected.

**Step 3.1 — Search for unqualified TrendDirection usage**
```bash
grep -rn "TrendDirection" --include="*.swift" StressMonitor/ | \
  grep -v "StressViewModel.TrendDirection" | \
  grep -v "private enum TrendDirection"
```

If any unqualified references exist outside StressViewModel, they may need `StressViewModel.TrendDirection` qualification, or the enum should be extracted to a shared types file.

**Step 3.2 (if needed) — Extract TrendDirection to shared types**
If there are unqualified references, move the enum from `StressViewModel` to a shared location:
```
StressMonitor/StressMonitor/Models/TrendDirection.swift
```

### Phase 4: Verification (10 min)

**Step 4.1 — Full build**
```bash
xcodebuild build -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet
```

**Step 4.2 — Run tests**
```bash
xcodebuild test -scheme StressMonitor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | tail -30
```

**Step 4.3 — Verify no dangling references**
```bash
grep -rn "DashboardViewModel" --include="*.swift" StressMonitor/
# Expected: 0 results (function name mockDashboardViewModel is fine — it returns StressViewModel)
```

**Step 4.4 — Verify TrendDirection references are clean**
```bash
grep -rn "TrendDirection" --include="*.swift" StressMonitor/
# Expected: All references resolve to StressViewModel.TrendDirection or private enums
```

### Phase 5: Commit & PR (5 min)

**Step 5.1 — Commit**
```bash
git add -A
git commit -m "refactor: delete dead DashboardViewModel — StressViewModel is the canonical implementation

- DashboardViewModel.swift was unused (zero instantiation sites)
- DashboardView already uses StressViewModel directly
- DashboardViewModel used outdated 2-factor algorithm vs 5-factor
- Top-level TrendDirection enum removed (StressViewModel.TrendDirection remains)
- No functional changes; pure deletion"
```

**Step 5.2 — Push and create PR**
```bash
git push -u origin refactor/consolidate-viewmodels
```

---

## 4. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Build fails after deletion | Low | Low | Only happens if something imported DashboardViewModel's TrendDirection — grep confirms no such usage |
| TrendDirection naming collision | Low | Low | Top-level enum removal may reveal hidden dependencies — full grep in Step 3.1 catches these |
| Runtime breakage | Very Low | Medium | Dead code cannot affect runtime — but verify in simulator |
| Test regression | Very Low | Low | Tests already target StressViewModel (DashboardViewModel has no test coverage) |

---

## 5. Post-Merge Cleanup (Optional, separate task)

- Rename `PreviewDataFactory.mockDashboardViewModel()` → `mockStressViewModel()` or `mockDashboardStressViewModel()` for clarity (the function name is fine — it returns `StressViewModel`)
- Update `docs/system-architecture.md` and `docs/codebase-summary.md` to remove DashboardViewModel references
- Update `docs/KANBAN-SHIP-READINESS.md` — remove the "Write tests for DashboardViewModel" checklist item (dead code doesn't need tests)
- Remove `DashboardViewModel.swift` from `repomix-output.xml` on next generation

---

## 6. Summary of Changes

| Action | File | Details |
|--------|------|---------|
| **DELETE** | `Views/Dashboard/DashboardViewModel.swift` | 130 lines removed (class + top-level TrendDirection) |
| **NO CHANGE** | `ViewModels/StressViewModel.swift` | Already the canonical ViewModel |
| **NO CHANGE** | `Views/DashboardView.swift` | Already uses StressViewModel |
| **NO CHANGE** | `Services/MockServices.swift` | `mockDashboardViewModel()` already returns StressViewModel |
| **POSSIBLE** | Any file using unqualified `TrendDirection` | May need `StressViewModel.` prefix |

**Net result:** ~130 lines deleted, 0 lines added, 0 functional changes.
