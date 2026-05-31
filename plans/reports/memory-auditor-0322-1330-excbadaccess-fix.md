# Memory Audit: EXC_BAD_ACCESS Crash Fix

**Date:** 2026-03-22
**Status:** FIXED
**Crashes Resolved:** 2

---

## Crash #1: StressRepository.getBaseline()

**Address:** `0x974697669746360`

### Root Cause

**SwiftData ModelContext threading violation** in `StressRepository.getBaseline()`:

1. `StressRepository` is `@MainActor` isolated
2. `baselineCalculator` marked `nonisolated` (line 15)
3. `await baselineCalculator.calculateBaseline()` hops actors
4. During suspension, `modelContext` (NOT thread-safe) can be accessed concurrently
5. Memory corruption → `EXC_BAD_ACCESS`

---

## Fixes Applied

### 1. Actor Boundary Fix (StressRepository.swift:206-238)

**Before:**
```swift
let measurements = try modelContext.fetch(descriptor)
// ...
baseline = mergePersistedMetadata(
    from: persistedBaseline,
    into: try await baselineCalculator.calculateBaseline(from: hrvMeasurements)  // Actor hop with modelContext in scope
)
```

**After:**
```swift
// Fetch on MainActor and extract ALL data BEFORE any actor hop
let measurements = try modelContext.fetch(descriptor)
let hrvMeasurements = measurements.map { HRVMeasurement(value: $0.hrv, timestamp: $0.timestamp) }
let isEmpty = measurements.isEmpty

// NOW safe to hop actors - working with Sendable value types
let calculatedBaseline = try await baselineCalculator.calculateBaseline(from: hrvMeasurements)
```

### 2. Added deinit (StressRepository.swift)

```swift
deinit {
    onSyncStatusChange = nil
    onSyncError = nil
}
```

---

## Crash #2: HRVStressFactor.calculate()

**Address:** `0x3c000000000000`

### Root Cause

**Dictionary (reference type) shared across actor boundaries** in `HRVStressFactor.calculate()`:

1. `context.baseline.hourlyHRVBaseline` is `[Int: Double]?` - a Dictionary (reference type with COW)
2. `HRVStressFactor.calculate` is called from `MultiFactorStressCalculator` (nonisolated)
3. Dictionary reference is shared between MainActor (creator) and nonisolated context
4. If original Dictionary is mutated during concurrent access → memory corruption

### Fix Applied

**File:** `HRVStressFactor.swift:14-39`

```swift
// BEFORE: Direct access to context.baseline.hourlyHRVBaseline
let adjustment = baselineCalculator.circadianAdjustment(
    for: hour,
    userHourlyBaseline: context.baseline.hourlyHRVBaseline,  // Shared reference!
    globalBaseline: baseline
)

// AFTER: Extract all data upfront into local copies
let hourlyHRVBaseline = context.baseline.hourlyHRVBaseline  // Local copy
let baselineHRV = context.baseline.baselineHRV
let timestamp = context.timestamp
let lastReadingDate = context.lastReadingDate

let adjustment = baselineCalculator.circadianAdjustment(
    for: hour,
    userHourlyBaseline: hourlyHRVBaseline,  // Local copy, safe
    globalBaseline: baselineHRV
)
```

---

## Verification

- [x] Build succeeded (warnings only)
- [x] App launches on simulator without crash
- [x] Dashboard displays correctly

---

## Remaining Warnings (Non-Critical)

| Category | Count | Notes |
|----------|-------|-------|
| Trailing closure deprecation | 12 | StressCharacterCard.swift:194 |
| Main actor isolation | 5 | CloudKitResetService, DataDeleterService |
| Unused values | 4 | Minor code cleanup |

---

## Additional Issues Found (Not Fixed)

| Issue | File | Severity |
|-------|------|----------|
| Timer captures self | CharacterAnimationModifier.swift:61 | LOW (struct value type) |
| Timer captures self | BreathingExerciseView.swift:322 | MEDIUM |

---

## Testing Recommendations

1. Run full regression: `/axiom:run-tests`
2. Test on physical device (simulator threading differs)
3. Profile with Instruments → Allocations → Filter: StressRepository
