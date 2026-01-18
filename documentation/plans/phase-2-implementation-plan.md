# Phase 2: Data Layer Implementation Plan

## Overview

This phase implements the core data layer services that power the stress monitoring application. We will build the HealthKit integration for fetching health data, implement the stress calculation algorithm with confidence scoring, create the repository for persisting measurements via SwiftData, add background scheduling for periodic health data updates, and build the main StressViewModel that coordinates all services for the UI layer.

## Files to Create

### 1. StressMonitor/Services/HealthKit/HealthKitManager.swift

Implements HealthKitServiceProtocol to handle all HealthKit interactions.

**Functions:**
- `init()` - Initializes HKHealthStore, sets up health store instance and defines sample types for HRV and heart rate queries
- `requestAuthorization() async throws` - Requests HealthKit permissions for HRV and heart rate reading access, throws authorization errors
- `fetchLatestHRV() async throws -> HRVMeasurement?` - Queries most recent HRV sample from HealthKit, converts to domain model, returns nil if no data
- `fetchHeartRate(samples: Int) async throws -> [HeartRateSample]` - Retrieves last N heart rate samples sorted by date descending, maps to domain models
- `fetchHRVHistory(since: Date) async throws -> [HRVMeasurement]` - Gets all HRV measurements after given date for baseline calculation
- `observeHeartRateUpdates() -> AsyncStream<HeartRateSample?>` - Sets up live query for real-time heart rate changes, yields values via async stream

### 2. StressMonitor/Services/Algorithm/StressCalculator.swift

Implements StressAlgorithmServiceProtocol with the core stress scoring algorithm.

**Functions:**
- `init()` - Initializes calculator with default constants for HRV weight (0.7), HR weight (0.3), and power exponent (0.8)
- `calculateStress(hrv: Double, heartRate: Double) async throws -> StressResult` - Runs stress calculation using normalized HRV and HR values, maps to 0-100 scale, determines category, returns complete result
- `calculateConfidence(hrv: Double, heartRate: Double, samples: Int) -> Double` - Computes confidence score based on HRV validity (must be >20ms), heart rate reasonableness (40-180 bpm), and sample history size
- `normalizeHRV(hrv: Double, baseline: Double) -> Double` - Calculates normalized HRV deviation: (baseline - HRV) / baseline, handles baseline edge cases
- `normalizeHeartRate(hr: Double, restingHR: Double) -> Double` - Normalizes heart rate: (hr - restingHR) / restingHR, clamps negative values
- `applyHRVCurve(_ normalized: Double) -> Double` - Applies power curve (normalized^0.8) to HRV component for non-linear stress response
- `applyHeartRateCurve(_ normalized: Double) -> Double` - Uses atan function for smooth heart rate contribution curve: atan(normalized * 2) / (π/2)
- `categorizeStress(_ level: Double) -> StressCategory` - Maps 0-100 stress level to category: 0-25 relaxed, 25-50 mild, 50-75 moderate, 75-100 high

### 3. StressMonitor/Services/Algorithm/BaselineCalculator.swift

Calculates and maintains personal baseline values for each user.

**Functions:**
- `init()` - Initializes calculator with default minimum sample count (30) and time window (30 days)
- `calculateBaseline(from measurements: [HRVMeasurement]) async throws -> PersonalBaseline` - Computes average HRV from samples, determines resting heart rate from minimum readings, validates minimum sample requirement
- `calculateRestingHeartRate(from samples: [HeartRateSample]) -> Double` - Finds lowest 10th percentile of heart rate readings as baseline resting rate
- `shouldUpdateBaseline(lastUpdate: Date, samples: Int) -> Bool` - Determines if baseline needs recalculation based on age (weekly check) and new sample count
- `validateSampleCount(_ count: Int) throws` - Throws error if insufficient samples for reliable baseline calculation
- `filterOutliers(_ measurements: [HRVMeasurement]) -> [HRVMeasurement]` - Removes statistical outliers using IQR method (values outside 1.5 * IQR)

### 4. StressMonitor/Services/Repository/StressRepository.swift

Implements StressRepositoryProtocol for SwiftData persistence operations.

**Functions:**
- `init(modelContext: ModelContext)` - Stores SwiftData ModelContext for database operations
- `save(_ measurement: StressMeasurement) async throws` - Inserts new stress measurement into SwiftData, handles context save and persistence errors
- `fetchRecent(limit: Int) async throws -> [StressMeasurement]` - Fetches latest N measurements sorted by timestamp descending, returns empty array if none exist
- `fetchAll() async throws -> [StressMeasurement]` - Retrieves all stored measurements for history and export functionality
- `deleteOlderThan(_ date: Date) async throws` - Removes measurements older than specified date for data cleanup and storage management
- `getBaseline() async throws -> PersonalBaseline` - Calculates or retrieves cached personal baseline from HRV measurements, delegates to BaselineCalculator
- `updateBaseline(_ baseline: PersonalBaseline) async throws` - Persists updated baseline values, invalidates any cached baseline data

### 5. StressMonitor/Services/Background/HealthBackgroundScheduler.swift

Manages background HealthKit data fetching using BGAppRefreshTask.

**Functions:**
- `init()` - Initializes scheduler with HealthKit service reference and background task identifier
- `scheduleBackgroundRefresh() async throws` - Requests background app refresh with minimum interval, schedules next fetch window
- `handleBackgroundRefresh(task: BGAppRefreshTask)` - Background task handler that fetches latest HRV and heart rate, calculates stress, saves to repository, marks task complete
- `cancelAllTasks()` - Cancels any pending background refresh tasks for clean shutdown
- `fetchAndCalculateStress() async throws` - Helper method that fetches health data, runs stress calculation, persists results via repository

### 6. StressMonitor/ViewModels/StressViewModel.swift

Main view model coordinating all services for the dashboard and settings views.

**Functions:**
- `init(healthKit: HealthKitServiceProtocol, algorithm: StressAlgorithmServiceProtocol, repository: StressRepositoryProtocol)` - Constructor injection of all service dependencies, sets up initial state
- `loadCurrentStress() async` - Fetches latest HRV and heart rate in parallel, calculates stress level, updates currentStress property with result
- `loadHistoricalData(days: Int) async` - Loads past N days of measurements from repository, populates historicalData array for charts
- `loadBaseline() async` - Retrieves personal baseline from repository, updates baseline property for UI display
- `refreshHealthData() async` - Manual refresh trigger that reloads current stress and updates last refresh timestamp
- `observeHeartRate()` - Sets up async stream for real-time heart rate updates, updates liveHeartRate property as new readings arrive
- `calculateAndSaveStress() async throws` - Orchestrates full flow: fetch health data, calculate stress, save result to repository
- `clearError()` - Resets errorMessage property to nil for UI error dismissal

**Properties:**
- `currentStress: StressResult?` - Latest calculated stress value for dashboard display
- `historicalData: [StressMeasurement]` - Array of past measurements for trend charts
- `baseline: PersonalBaseline?` - User's personal baseline values
- `liveHeartRate: Double?` - Real-time heart rate from HealthKit observer
- `isLoading: Bool` - Loading state for UI activity indicators
- `errorMessage: String?` - Error message for user-facing alerts
- `lastRefresh: Date?` - Timestamp of last successful data refresh

## Files to Modify

### 1. StressMonitor/StressMonitorApp.swift

Update app initialization to register SwiftData models and services.

**Changes:**
- Add `modelContainer` initialization with StressMeasurement model
- Set up dependency injection container for service protocols
- Register background task scheduler on app launch
- Configure initial HealthKit authorization flow

### 2. StressMonitor/Views/DashboardView.swift

Connect dashboard UI to StressViewModel for data binding.

**Changes:**
- Add `@State private var viewModel = StressViewModel()` instance
- Bind currentStress property to stress ring component
- Call `loadCurrentStress()` on view appear with `.task {}`
- Display loading state and error alerts based on viewModel properties
- Update heart rate display from liveHeartRate stream

### 3. StressMonitor/Views/HistoryView.swift

Connect history view to historical data from StressViewModel.

**Changes:**
- Add `@State private var viewModel = StressViewModel()` instance
- Call `loadHistoricalData(days: 7)` on view appear
- Bind historicalData array to chart component
- Implement pull-to-refresh calling `refreshHealthData()`

## Implementation Order

1. **HealthKitManager** - Foundation for all health data access
2. **StressCalculator** - Core algorithm, no dependencies on other services
3. **BaselineCalculator** - Independent baseline computation logic
4. **StressRepository** - Data persistence, depends on models being complete
5. **StressViewModel** - Coordination layer, requires all services
6. **HealthBackgroundScheduler** - Optional enhancement, requires repository
7. **View Updates** - Connect UI to completed view model

## Testing Strategy

Create corresponding test files in `StressMonitorTests/`:
- `HealthKitManagerTests.swift` - Mock HealthKit store responses
- `StressCalculatorTests.swift` - Verify algorithm outputs with known inputs
- `BaselineCalculatorTests.swift` - Test baseline calculation with sample data
- `StressRepositoryTests.swift` - Use in-memory SwiftData container
- `StressViewModelTests.swift` - Mock all service protocols

## Success Criteria

- HealthKit successfully returns HRV and heart rate data
- Stress algorithm produces values in 0-100 range with correct categories
- Baseline calculator handles edge cases (low samples, outliers)
- SwiftData persists and retrieves measurements correctly
- StressViewModel coordinates services without errors
- Dashboard displays live stress data from HealthKit
- Background scheduler can fetch and save data without crash
- All unit tests pass with >80% coverage
