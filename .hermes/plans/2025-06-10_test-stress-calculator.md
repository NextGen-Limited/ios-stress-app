# Implementation Plan: Unit Tests for MultiFactorStressCalculator

**Task ID:** t_42f30aaf  
**Priority:** P1  
**Branch:** `test/multifactor-stress-calculator`  
**Date:** 2025-06-10  
**Target:** StressMonitorWatch Watch AppTests (Swift Testing framework)

---

## 1. Executive Summary

Write comprehensive unit tests for the `MultiFactorStressCalculator` — the core stress calculation algorithm of the StressMonitor app. The tests cover all 5 `StressFactor` implementations (HRV, HeartRate, Sleep, Activity, Recovery), weight normalization, confidence scoring, composite score calculation, `FactorBreakdown` assembly, and edge cases. Tests use the Swift Testing framework (`import Testing`, `@Test`, `#expect`) to match the existing watch test target convention.

---

## 2. Codebase Analysis

### 2.1 Source Files Under Test

| File | Location | Key Type |
|------|----------|----------|
| `MultiFactorStressCalculator.swift` | Watch App/Services/ | `final class MultiFactorStressCalculator` |
| `StressFactor.swift` | Watch App/Services/ | `protocol StressFactor`, `struct FactorResult` |
| `StressCalculator.swift` | Watch App/Services/ | `final class StressCalculator` (fallback) |
| `BaselineCalculator.swift` | Watch App/Services/ | `final class BaselineCalculator` |
| `HRVStressFactor.swift` | Watch App/Services/ | `struct HRVStressFactor` |
| `HeartRateStressFactor.swift` | Watch App/Services/ | `struct HeartRateStressFactor` |
| `SleepStressFactor.swift` | Watch App/Services/ | `struct SleepStressFactor` |
| `ActivityStressFactor.swift` | Watch App/Services/ | `struct ActivityStressFactor` |
| `RecoveryStressFactor.swift` | Watch App/Services/ | `struct RecoveryStressFactor` |
| `StressAlgorithmServiceProtocol.swift` | Watch App/Services/ | Protocol + default extension |

### 2.2 Model Files

| File | Key Types |
|------|-----------|
| `StressContext.swift` | `StressContext` (input context) |
| `StressResult.swift` | `StressResult`, `StressResult.category(for:)` |
| `StressCategory.swift` | `enum StressCategory` |
| `FactorBreakdown.swift` | `FactorBreakdown` |
| `FactorWeights.swift` | `FactorWeights`, `FactorWeights.defaults` |
| `PersonalBaseline.swift` | `PersonalBaseline` |
| `SleepData.swift` | `SleepData` |
| `ActivityData.swift` | `ActivityData` |
| `RecoveryData.swift` | `RecoveryData` |
| `HRVMeasurement.swift` | `HRVMeasurement` |
| `HeartRateSample.swift` | `HeartRateSample` |

### 2.3 Key Algorithm Details

**Default Weights** (from `FactorWeights.defaults`):
- HRV: 0.40, HeartRate: 0.15, Sleep: 0.20, Activity: 0.15, Recovery: 0.10
- Total: 1.0

**Composite Score Calculation** (`calculateMultiFactorStress`):
1. Iterate all factors, call `factor.calculate(context:)`, collect non-nil results
2. If no results → throw `StressError.noData`
3. `availableWeight` = sum of effective weights for returned factors
4. `totalWeight` = sum of effective weights for ALL registered factors
5. `compositeScore` = Σ(value × weight/availableWeight) — weights normalized among available
6. `level` = clamp(compositeScore × 100, 0…100)
7. `dataCompleteness` = availableWeight / totalWeight
8. `avgConfidence` = mean of all factor confidences
9. Final `confidence` = dataCompleteness × 0.4 + avgConfidence × 0.6
10. Build `FactorBreakdown` from individual results by factor id
11. Return `StressResult(level, category, confidence, hrv, heartRate, timestamp, breakdown)`

**Effective Weight Resolution** (`effectiveWeight`):
- If `calibratedWeights` is nil → use `factor.weight` (protocol default)
- If `calibratedWeights` exists → lookup by `factor.id` in calibrated map; fallback to `factor.weight` for unknown ids

**Stress Category Mapping** (from `StressResult.category(for:)`):
- 0..<25 → `.relaxed`
- 25..<50 → `.mild`
- 50..<75 → `.moderate`
- default (≥75) → `.high`

### 2.4 Factor Implementation Details

**HRVStressFactor** (id="hrv", weight=0.40):
- Returns nil if `context.hrv == nil` or `baseline.baselineHRV <= 0`
- Circadian-adjusted baseline via `BaselineCalculator`
- `normalized = (adjustedBaseline - hrv) / adjustedBaseline`, clamped [0, 2]
- `value = sigmoid(clamped, k=4.0, x0=0.5)`
- Confidence: lower for hrv < 20, penalized by recency of lastReadingDate

**HeartRateStressFactor** (id="heartRate", weight=0.15):
- Returns nil if `context.heartRate == nil` or `baseline.restingHeartRate <= 0`
- `normalized = (hr - resting) / resting`, clamped [0, 2]
- `value = sigmoid(clamped, k=3.0, x0=0.3)`
- Confidence: always 1.0

**SleepStressFactor** (id="sleep", weight=0.20):
- Returns nil if `context.sleepData == nil`
- `durationStress = clamp((8 - totalSleep) / 4, 0, 1)`
- `qualityStress = 1 - (deep + rem) / total` (if total > 0, else 0)
- `efficiencyStress = 1 - sleepEfficiency`
- Combined: duration×0.40 + quality×0.35 + efficiency×0.25
- Confidence: 0.85

**ActivityStressFactor** (id="activity", weight=0.15):
- Returns nil if `context.activityData == nil`
- `stepStress = 1 - min(steps/10000, 1)`
- `energyStress = 1 - min(energy/300, 1)`
- `standStress = 1 - min(stand/10, 1)`
- Combined: steps×0.40 + energy×0.35 + stand×0.25
- Post-workout reduction if lastWorkout < 2h ago
- Confidence: 0.85

**RecoveryStressFactor** (id="recovery", weight=0.10):
- Returns nil if `context.recoveryData == nil` OR all sub-components nil
- Components: respiratoryRate (w=0.40), bloodOxygen (w=0.30), restingHRTrend (w=0.30)
- Weights renormalized among available components
- Confidence: 0.6 + (componentCount / 3.0) × 0.3

### 2.5 Existing Test Patterns

- **iOS tests** (`StressMonitorTests/`) use `XCTest` framework
- **Watch tests** (`StressMonitorWatch Watch AppTests/`) use Swift Testing framework (`import Testing`, `@Test`, `#expect`)
- No `MockServices.swift` file exists yet — the task context mentions it, but it needs to be created
- The watch test target currently has only a placeholder test

---

## 3. TDD Approach

### Phase 1: Write Test Scaffolding & Mocks (RED)
### Phase 2: Verify Tests Compile & Fail (RED validation)
### Phase 3: Ensure Existing Code Passes All Tests (GREEN)
### Phase 4: Add Edge Case & Boundary Tests (expand coverage)
### Phase 5: Run Full Suite & Verify (GREEN validation)

Since the production code already exists, TDD here means:
1. Write tests that document the expected behavior
2. Run them against the existing code to confirm correctness
3. Add edge case tests that may reveal bugs
4. Document any behavioral findings

---

## 4. Test File Structure

All test files go in:  
`StressMonitor/StressMonitorWatch Watch AppTests/`

Using Swift Testing framework (`import Testing`, `@Test`, `#expect`) to match existing convention.

### Files to Create

| # | File | Purpose |
|---|------|---------|
| 1 | `TestHelpers.swift` | Shared test utilities, factory methods for test data |
| 2 | `MockStressFactor.swift` | Controllable mock implementing `StressFactor` |
| 3 | `MultiFactorStressCalculatorTests.swift` | Core calculator integration tests |
| 4 | `HRVStressFactorTests.swift` | HRV factor unit tests |
| 5 | `HeartRateStressFactorTests.swift` | Heart rate factor unit tests |
| 6 | `SleepStressFactorTests.swift` | Sleep factor unit tests |
| 7 | `ActivityStressFactorTests.swift` | Activity factor unit tests |
| 8 | `RecoveryStressFactorTests.swift` | Recovery factor unit tests |
| 9 | `WeightNormalizationTests.swift` | Weight normalization & effective weight tests |
| 10 | `ConfidenceScoringTests.swift` | Confidence calculation tests |

---

## 5. Detailed Test Cases

### 5.1 TestHelpers.swift — Shared Utilities

```
struct TestHelpers {
    // Factory: default baseline (HRV=50, restingHR=60)
    static func makeBaseline(...) -> PersonalBaseline
    
    // Factory: baseline with hourly HRV map
    static func makeBaselineWithHourly(hourly: [Int: Double]) -> PersonalBaseline
    
    // Factory: StressContext builder with optional fields
    static func makeContext(
        hrv: Double? = nil,
        heartRate: Double? = nil,
        sleepData: SleepData? = nil,
        activityData: ActivityData? = nil,
        recoveryData: RecoveryData? = nil,
        baseline: PersonalBaseline = makeBaseline(),
        lastReadingDate: Date? = nil
    ) -> StressContext
    
    // Factory: SleepData builder
    static func makeSleepData(
        totalSleepHours: Double = 7.5,
        deepSleepHours: Double = 1.5,
        remSleepHours: Double = 1.5,
        coreSleepHours: Double = 4.0,
        awakenings: Int = 2,
        timeInBedHours: Double = 8.0,
        sleepEfficiency: Double = 0.94
    ) -> SleepData
    
    // Factory: ActivityData builder
    static func makeActivityData(
        stepCount: Int = 8000,
        activeEnergyKcal: Double = 250,
        standHours: Int = 8,
        lastWorkoutEndTime: Date? = nil
    ) -> ActivityData
    
    // Factory: RecoveryData builder
    static func makeRecoveryData(
        respiratoryRate: Double? = 14,
        bloodOxygen: Double? = 97,
        restingHRTrend: Double? = 2.0
    ) -> RecoveryData
    
    // Factory: FactorWeights builder
    static func makeFactorWeights(
        hrv: Double = 0.40,
        heartRate: Double = 0.15,
        sleep: Double = 0.20,
        activity: Double = 0.15,
        recovery: Double = 0.10
    ) -> FactorWeights
}
```

### 5.2 MockStressFactor.swift — Controllable Mock

```
struct MockStressFactor: StressFactor {
    let id: String
    let weight: Double
    var result: FactorResult?
    var shouldThrow: Error?
    
    func calculate(context: StressContext) async throws -> FactorResult? {
        if let error = shouldThrow { throw error }
        return result
    }
}
```

This mock allows:
- Setting arbitrary `id` and `weight`
- Returning a specific `FactorResult` or `nil`
- Throwing errors on demand

### 5.3 MultiFactorStressCalculatorTests.swift — Core Calculator

#### Test Group: Basic Initialization
1. **`testDefaultInitialization`** — Init with no args, verify 5 default factors registered
2. **`testCustomFactorsInitialization`** — Init with custom factors array, verify used
3. **`testInitWithCalibratedWeights`** — Verify calibrated weights stored and used

#### Test Group: calculateMultiFactorStress — Happy Path
4. **`testAllFactorsAvailable`** — All 5 factors return results → verify composite score is weighted average with full-weight normalization
5. **`testOnlyHRVAvailable`** — Only HRV factor returns result → score = HRV value × 100, dataCompleteness reflects 1 factor's weight portion
6. **`testOnlyHeartRateAvailable`** — Only HR factor returns result → score based solely on HR
7. **`testOnlySleepAvailable`** — Only sleep factor returns result
8. **`testHRVAndHeartRateOnly`** — Two primary factors available → weights renormalized

#### Test Group: calculateMultiFactorStress — No Data
9. **`testNoFactorsReturnData_throwsNoData`** — All factors return nil → throws `StressError.noData`
10. **`testEmptyFactorsArray_throwsNoData`** — Init with empty factors → throws on calculate

#### Test Group: Score Clamping
11. **`testScoreClampedTo100`** — If weighted composite > 1.0 → level capped at 100
12. **`testScoreClampedTo0`** — If weighted composite < 0 → level floored at 0

#### Test Group: FactorBreakdown Assembly
13. **`testBreakdownContainsHRVComponent`** — Verify `factorBreakdown.hrvComponent` populated
14. **`testBreakdownContainsHRComponent`** — Verify `factorBreakdown.hrComponent` populated
15. **`testBreakdownContainsSleepComponent`** — Verify `factorBreakdown.sleepComponent` populated
16. **`testBreakdownContainsActivityComponent`** — Verify `factorBreakdown.activityComponent` populated
17. **`testBreakdownContainsRecoveryComponent`** — Verify `factorBreakdown.recoveryComponent` populated
18. **`testBreakdownNilForMissingFactors`** — If a factor returns nil → corresponding component is nil in breakdown
19. **`testBreakdownDataCompleteness`** — Verify `dataCompleteness` matches availableWeight/totalWeight

#### Test Group: Stress Category Mapping
20. **`testCategoryRelaxed`** — Level < 25 → `.relaxed`
21. **`testCategoryMild`** — 25 ≤ Level < 50 → `.mild`
22. **`testCategoryModerate`** — 50 ≤ Level < 75 → `.moderate`
23. **`testCategoryHigh`** — Level ≥ 75 → `.high`
24. **`testCategoryBoundaryAt25`** — Level exactly 25 → `.mild` (boundary test)
25. **`testCategoryBoundaryAt50`** — Level exactly 50 → `.moderate`
26. **`testCategoryBoundaryAt75`** — Level exactly 75 → `.high`

#### Test Group: Fallback Delegation
27. **`testCalculateStressDelegatesToFallback`** — `calculateStress(hrv:heartRate:)` delegates to StressCalculator
28. **`testCalculateConfidenceDelegatesToFallback`** — `calculateConfidence(...)` delegates to StressCalculator

#### Test Group: Real Factor Integration
29. **`testRealFactorsLowStressScenario`** — High HRV (60ms), normal HR (65bpm), good sleep (8h), active (10k steps) → expect relaxed/mild
30. **`testRealFactorsHighStressScenario`** — Low HRV (20ms), high HR (100bpm), poor sleep (4h), sedentary (2k steps) → expect moderate/high

### 5.4 HRVStressFactorTests.swift

#### Test Group: Nil Returns
1. **`testReturnsNilWhenHRVIsNil`** — context.hrv = nil → nil
2. **`testReturnsNilWhenBaselineHRVIsZero`** — baseline.baselineHRV = 0 → nil
3. **`testReturnsNilWhenBaselineHRVIsNegative`** — baseline.baselineHRV = -10 → nil

#### Test Group: Value Calculation
4. **`testLowHRVHighStress`** — hrv=20, baseline=50 → value near 1.0 (high stress)
5. **`testHighHRVLowStress`** — hrv=60, baseline=50 → value near 0.0 (low stress)
6. **`testHRVEqualsBaseline`** — hrv=50, baseline=50 → value ≈ sigmoid(0, ...) ≈ 0.386 (moderate)
7. **`testHRVAboveBaseline`** — hrv=80 > baseline=50 → normalized negative, clamped to 0 → sigmoid(0) ≈ 0.386
8. **`testVeryLowHRV`** — hrv=5, baseline=50 → high normalized value → high stress value
9. **`testHRVZero`** — hrv=0, baseline=50 → maximum normalized → high stress

#### Test Group: Confidence
10. **`testConfidenceHighHRV`** — hrv=50 → confidence ≈ 1.0
11. **`testConfidenceLowHRV`** — hrv=10 → confidence reduced (max(0.3, 10/20) = 0.5)
12. **`testConfidenceWithRecentReading`** — lastReadingDate = now → high confidence
13. **`testConfidenceWithStaleReading`** — lastReadingDate = 2h ago → reduced confidence
14. **`testConfidenceWithNilReadingDate`** — lastReadingDate = nil → no recency penalty

#### Test Group: Circadian Adjustment
15. **`testCircadianAdjustmentApplied`** — With hourly baseline, verify adjusted baseline differs
16. **`testCircadianAdjustmentFallback`** — No hourly baseline → uses default circadian curve

#### Test Group: Metadata
17. **`testMetadataContainsHRVAndBaseline`** — Verify metadata dict has "hrv" and "baseline" keys

### 5.5 HeartRateStressFactorTests.swift

#### Test Group: Nil Returns
1. **`testReturnsNilWhenHRIsNil`** — context.heartRate = nil → nil
2. **`testReturnsNilWhenRestingHRIsZero`** — baseline.restingHeartRate = 0 → nil
3. **`testReturnsNilWhenRestingHRIsNegative`** — baseline.restingHeartRate = -5 → nil

#### Test Group: Value Calculation
4. **`testHREqualsResting`** — hr=60, resting=60 → normalized=0 → sigmoid(0, k=3, x0=0.3) ≈ 0.29
5. **`testHRAboveResting`** — hr=80, resting=60 → normalized=0.33 → sigmoid ≈ moderate stress
6. **`testHRWellAboveResting`** — hr=120, resting=60 → normalized=1.0 → high stress
7. **`testHRBelowResting`** — hr=50, resting=60 → normalized<0, clamped to 0 → low stress
8. **`testHRFarAboveResting`** — hr=180, resting=60 → normalized=2.0, clamped to 2.0

#### Test Group: Confidence
9. **`testConfidenceAlways1`** — confidence = 1.0 for all inputs

#### Test Group: Metadata
10. **`testMetadataContainsHeartRate`** — metadata["heartRate"] == input HR

### 5.6 SleepStressFactorTests.swift

#### Test Group: Nil Returns
1. **`testReturnsNilWhenNoSleepData`** — context.sleepData = nil → nil

#### Test Group: Duration Component
2. **`testOptimalSleep`** — 8h sleep → durationStress ≈ 0
3. **`testShortSleep`** — 4h sleep → durationStress = (8-4)/4 = 1.0
4. **`testExcessiveSleep`** — 10h sleep → durationStress clamped to 0 (8-10 = -2, max(0,...)=0)
5. **`testSixHoursSleep`** — 6h sleep → durationStress = 0.5

#### Test Group: Quality Component
6. **`testHighRestorative`** — deep+rem = 50% of total → qualityStress = 0.5
7. **`testLowRestorative`** — deep+rem = 10% of total → qualityStress = 0.9
8. **`testZeroTotalSleep`** — totalSleep=0 → restorativeProportion=0 → qualityStress=1.0

#### Test Group: Efficiency Component
9. **`testPerfectEfficiency`** — efficiency=1.0 → efficiencyStress=0
10. **`testPoorEfficiency`** — efficiency=0.6 → efficiencyStress=0.4
11. **`testZeroEfficiency`** — efficiency=0 → efficiencyStress=1.0

#### Test Group: Combined Score
12. **`testIdealSleep`** — 8h, 50% restorative, 0.95 efficiency → low combined score
13. **`testTerribleSleep`** — 3h, 5% restorative, 0.4 efficiency → high combined score

#### Test Group: Confidence
14. **`testConfidenceAlways085`** — confidence = 0.85 always

### 5.7 ActivityStressFactorTests.swift

#### Test Group: Nil Returns
1. **`testReturnsNilWhenNoActivityData`** — context.activityData = nil → nil

#### Test Group: Component Scores
2. **`test10kSteps`** — stepCount=10000 → stepStress=0
3. **`test5kSteps`** — stepCount=5000 → stepStress=0.5
4. **`test0Steps`** — stepCount=0 → stepStress=1.0
5. **`test300Energy`** — activeEnergyKcal=300 → energyStress=0
6. **`test150Energy`** — activeEnergyKcal=150 → energyStress=0.5
7. **`test10StandHours`** — standHours=10 → standStress=0
8. **`test5StandHours`** — standHours=5 → standStress=0.5

#### Test Group: Combined Score
9. **`testVeryActive`** — 10k steps, 300 kcal, 10 stand → combined ≈ 0 (low stress)
10. **`testSedentary`** — 0 steps, 0 kcal, 0 stand → combined ≈ 1.0 (high stress)
11. **`testModerateActivity`** — midrange values → moderate combined

#### Test Group: Post-Workout Reduction
12. **`testRecentWorkoutReducesStress`** — lastWorkout 30min ago → stress reduced by factor
13. **`testOldWorkoutNoEffect`** — lastWorkout 3h ago → no reduction
14. **`testNoWorkoutData`** — lastWorkoutEndTime=nil → no reduction

#### Test Group: Confidence
15. **`testConfidenceAlways085`** — confidence = 0.85 always

### 5.8 RecoveryStressFactorTests.swift

#### Test Group: Nil Returns
1. **`testReturnsNilWhenNoRecoveryData`** — context.recoveryData = nil → nil
2. **`testReturnsNilWhenAllComponentsNil`** — respiratoryRate=nil, bloodOxygen=nil, restingHRTrend=nil → nil

#### Test Group: Component Values
3. **`testNormalRespiratoryRate`** — rr=14 → (14-12)/16 = 0.125
4. **`testHighRespiratoryRate`** — rr=24 → (24-12)/16 = 0.75
5. **`testLowRespiratoryRate`** — rr=10 → max(0, (10-12)/16) = 0
6. **`testNormalBloodOxygen`** — spo2=98 → (100-98)/8 = 0.25
7. **`testLowBloodOxygen`** — spo2=90 → (100-90)/8 = 1.25, clamped to 1.0
8. **`testHighBloodOxygen`** — spo2=100 → (100-100)/8 = 0
9. **`testHRTRendZero`** — trend=0 → 0
10. **`testHRTRendElevated`** — trend=8 → 8/10 = 0.8

#### Test Group: Weight Renormalization
11. **`testSingleComponentRR`** — Only RR available → weight renormalized to 1.0
12. **`testTwoComponents`** — RR + SpO2 → weights renormalized (0.40→0.57, 0.30→0.43)
13. **`testAllThreeComponents`** — All available → original weights

#### Test Group: Confidence Scaling
14. **`testConfidenceOneComponent`** — 1 component → 0.6 + 1/3×0.3 = 0.7
15. **`testConfidenceTwoComponents`** — 2 components → 0.6 + 2/3×0.3 = 0.8
16. **`testConfidenceThreeComponents`** — 3 components → 0.6 + 3/3×0.3 = 0.9

### 5.9 WeightNormalizationTests.swift

#### Test Group: Default Weights
1. **`testDefaultWeightsSumToOne`** — FactorWeights.defaults.total == 1.0
2. **`testDefaultWeightValues`** — HRV=0.40, HR=0.15, Sleep=0.20, Activity=0.15, Recovery=0.10

#### Test Group: Effective Weight Resolution (via mock factors)
3. **`testEffectiveWeightWithoutCalibration`** — No calibratedWeights → uses factor.weight
4. **`testEffectiveWeightWithCalibration`** — calibratedWeights provided → uses calibrated value
5. **`testEffectiveWeightFallbackForUnknownId`** — Unknown factor id → uses factor.weight
6. **`testEffectiveWeightForHRV`** — id="hrv" → calibratedWeights.hrv
7. **`testEffectiveWeightForHeartRate`** — id="heartRate" → calibratedWeights.heartRate
8. **`testEffectiveWeightForSleep`** — id="sleep" → calibratedWeights.sleep
9. **`testEffectiveWeightForActivity`** — id="activity" → calibratedWeights.activity
10. **`testEffectiveWeightForRecovery`** — id="recovery" → calibratedWeights.recovery

#### Test Group: Weight Normalization When Factors Missing
11. **`testPartialFactors_weightsRenormalized`** — 3 of 5 factors → availableWeight < totalWeight, composite uses renormalized weights
12. **`testSingleFactor_weightBecomesOne`** — Only 1 factor → weight/availableWeight = 1.0

#### Test Group: Data Completeness
13. **`testAllFactorsComplete_completenessIsOne`** — All factors available → dataCompleteness = 1.0
14. **`testNoFactorsZeroWeight`** — Edge: factor returns nil → excluded from availableWeight

### 5.10 ConfidenceScoringTests.swift

#### Test Group: Final Confidence Formula
1. **`testFullConfidence_allFactorsHighConfidence`** — dataCompleteness=1.0, avgConfidence=1.0 → final = 1.0×0.4 + 1.0×0.6 = 1.0
2. **`testHalfData_allHighConfidence`** — dataCompleteness=0.5, avgConfidence=1.0 → final = 0.5×0.4 + 1.0×0.6 = 0.8
3. **`testFullData_lowConfidence`** — dataCompleteness=1.0, avgConfidence=0.5 → final = 1.0×0.4 + 0.5×0.6 = 0.7
4. **`testMinimalData_lowConfidence`** — dataCompleteness=0.15, avgConfidence=0.3 → final ≈ 0.24

#### Test Group: Factor-Level Confidence Contributions
5. **`testHRVConfidenceDecreasesWithLowHRV`** — hrv=10 → factor confidence < 0.5
6. **`testHRVConfidenceDecreasesWithStaleReading`** — lastReading 90min ago → reduced
7. **`testSleepConfidenceConstant`** — Always 0.85
8. **`testActivityConfidenceConstant`** — Always 0.85
9. **`testRecoveryConfidenceScalesWithComponents`** — More data → higher confidence

#### Test Group: Fallback Calculator Confidence
10. **`testFallbackConfidenceHighHRV_normalHR`** — hrv=50, hr=70, samples=10 → high confidence
11. **`testFallbackConfidenceLowHRV`** — hrv=10 → reduced
12. **`testFallbackConfidenceExtremeHR`** — hr=180 → reduced
13. **`testFallbackConfidenceFewSamples`** — samples=1 → reduced
14. **`testFallbackConfidenceStaleReading`** — lastReading 60min ago → reduced

---

## 6. Implementation Order (TDD Phases)

### Phase 1: Create Test Infrastructure (RED)
1. Create branch `test/multifactor-stress-calculator`
2. Create `TestHelpers.swift` with all factory methods
3. Create `MockStressFactor.swift`
4. Create all test files with test method signatures and `#expect` assertions
5. Verify files compile (they will reference existing production types)

### Phase 2: Individual Factor Tests (GREEN validation)
1. Write and run `HeartRateStressFactorTests` — simplest factor, no external deps
2. Write and run `SleepStressFactorTests` — pure data transform
3. Write and run `ActivityStressFactorTests` — similar pattern
4. Write and run `RecoveryStressFactorTests` — partial data handling
5. Write and run `HRVStressFactorTests` — most complex (circadian, confidence)

### Phase 3: Calculator Integration Tests (GREEN validation)
1. Write and run `WeightNormalizationTests` using mock factors
2. Write and run `ConfidenceScoringTests`
3. Write and run `MultiFactorStressCalculatorTests` — full integration

### Phase 4: Edge Cases & Stress Tests
1. Add boundary value tests (exact category thresholds)
2. Add extreme input tests (very high/low HRV, HR)
3. Add concurrent calculation tests (Sendable compliance)
4. Add tests for custom factor lists (empty, duplicates, unknown ids)

### Phase 5: Xcode Project Integration
1. Add all new test files to `StressMonitorWatch Watch AppTests` target in Xcode project
2. Run full test suite: `xcode_test(scheme: "StressMonitorWatch", onlyTesting: ["StressMonitorWatch Watch AppTests"])`
3. Verify all tests pass

---

## 7. Test Execution Strategy

### Run Command
```
# Run all new tests
xcode_test(
    scheme: "StressMonitorWatch",
    destination: "platform=watchOS Simulator,name=Apple Watch Series 9",
    only_testing: ["StressMonitorWatch_Watch_AppTests"]
)

# Run specific test file
xcode_test(
    scheme: "StressMonitorWatch",
    only_testing: ["StressMonitorWatch_Watch_AppTests/MultiFactorStressCalculatorTests"]
)
```

### Coverage Targets
- `MultiFactorStressCalculator`: ≥ 95% line coverage
- Individual factors: ≥ 90% line coverage each
- Overall new code coverage: ≥ 90%

---

## 8. Key Design Decisions

1. **Swift Testing over XCTest** — Matches existing watch test target convention
2. **MockStressFactor over real factors** — For calculator unit tests, mock factors give precise control over weight normalization and confidence calculations
3. **Real factors tested directly** — Each factor's own test file uses real implementations with controlled `StressContext` inputs
4. **No HealthKit mocking needed** — Factors are pure functions of `StressContext`; HealthKit is a layer above
5. **No MockServices.swift** — The task context mentioned it, but no such file exists. Our `MockStressFactor` + `TestHelpers` approach is cleaner for the actual testing needs

---

## 9. Potential Bugs to Watch For

Based on code analysis, these areas may have edge case issues:

1. **HRV above baseline** — When hrv > adjustedBaseline, normalized goes negative, clamped to 0, sigmoid(0, k=4, x0=0.5) ≈ 0.119. This means "excellent HRV" still shows ~12% stress, not 0%.
2. **RecoveryData with all nil sub-fields** — `RecoveryData` itself exists but all optional fields are nil → should return nil (guard at end catches this).
3. **ActivityData with zero everything** — All stress components = 1.0, combined = 1.0. No workout, so no reduction. Maximum activity stress.
4. **Empty factors array** — `MultiFactorStressCalculator(factors: [])` — results.isEmpty → throws noData. totalWeight = 0 → division by zero in dataCompleteness? Needs investigation.
5. **SleepData with totalSleepHours=0** — deep+rem/total = div-by-zero, but code has `totalSleepHours > 0` guard (falls to 0), so qualityStress=1.0.
6. **Calibrated weights sum != 1.0** — No validation. If user calibration produces weights summing to e.g. 0.8, normalization still works but totalWeight != 1.0.

---

## 10. Summary Statistics

- **Total test files**: 10
- **Total test cases**: ~80+
- **Estimated LOC**: ~1,500–2,000
- **Estimated effort**: 1 session
