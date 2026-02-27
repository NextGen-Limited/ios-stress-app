# Test Results Report

**Project:** StressMonitor iOS App
**Date:** 2026-02-23 23:09
**Scheme:** StressMonitor
**Device:** iPhone 17 Pro Max (iOS Simulator 26.1)
**Environment:** macOS 26.3

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 482 |
| Passed | 481 |
| Failed | 1 |
| Skipped | 0 |
| Pass Rate | 99.8% |
| Result | **FAILED** (1 failure) |

---

## Failed Test

### testAvailableFamiliesList() - StressMonitorTests

**Location:** `StressMonitorTests.swift`

**Error:**
```
Expectation failed: (families → [...font list...]).contains("System Font")
```

**Cause:** Test expects "System Font" to be in the list of available font families returned by `UIFont.familyNames`, but iOS doesn't include "System Font" as a named family - the system font (San Francisco) is accessed differently.

**Fix Recommendation:**
- Either remove this assertion or change it to check for an actual font family name (e.g., "Helvetica Neue" or "San Francisco" if available)
- The system font is typically accessed via `UIFont.systemFont(ofSize:)` not via family names

---

## Compiler Warnings (Swift 6 Concurrency)

Multiple warnings related to Swift 6 strict concurrency checking. These will become **errors** in Swift 6 mode:

### 1. Sendable Conformance Issues

| File | Issue |
|------|-------|
| `MockCloudKitManager.swift` | Non-final class cannot conform to Sendable |
| `MockCloudKitManager.swift` | Mutable stored property in Sendable class |
| `MockHealthKitService` | Mutable stored property `hrvToReturn` |
| `MockStressAlgorithmService` | Mutable stored property `stressToReturn` |
| `MockStressViewModelRepository` | Mutable stored property `measurementsToReturn` |
| `MockSuccessRepository` | Mutable stored property `baselineToReturn` |
| `MockOnboardingHealthKitService` | Mutable stored property `shouldSucceed` |

### 2. Main Actor Isolation Issues

Multiple warnings in `MockCloudKitManager.swift` about accessing main actor-isolated properties from nonisolated context:
- `StressMeasurement.init(record:)`
- Properties: `timestamp`, `stressLevel`, `hrv`, `level`

### 3. Unused Variable

| File | Line | Issue |
|------|------|-------|
| `StressCharacterCardTests.swift` | 225 | `expectedValue` initialized but never used |

---

## Performance Metrics

- **Test Duration:** ~585 seconds (~9.7 minutes)
- **Slowest Tests:** 3 tests with durations > 0.04s (3 standard deviations from mean)
- **Duration Breakdown:** 37% of time spent in 3 longest test runs

---

## Build Status

- **Build:** Success (with warnings)
- **Tests:** Failed (1 test failure)

---

## Critical Issues

1. **Test Failure:** `testAvailableFamiliesList()` - Invalid assertion checking for "System Font" in font family names

2. **Swift 6 Readiness:** Multiple mock classes will break in Swift 6 strict concurrency mode

---

## Recommendations

### High Priority
1. Fix `testAvailableFamiliesList()` test - remove or correct the "System Font" assertion
2. Mark mock classes with `@unchecked Sendable` or refactor to use `final` class with immutable properties

### Medium Priority
1. Address main actor isolation warnings in `MockCloudKitManager.swift`
2. Remove unused `expectedValue` variable in `StressCharacterCardTests.swift:225`

### Low Priority
1. Investigate slow tests for potential optimization
2. Add explicit await markers where missing

---

## Next Steps

1. Fix the failing test `testAvailableFamiliesList()`
2. Re-run tests to verify all pass
3. Create tickets for Swift 6 migration warnings

---

## Unresolved Questions

1. Should mock classes be refactored for Swift 6 compliance now or deferred?
2. What is the expected behavior for font family test - is "System Font" ever expected to appear?
