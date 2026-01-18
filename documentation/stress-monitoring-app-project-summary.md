# Stress Monitoring App - Project Summary

**Project Code Name:** StressWatch Clone
**Version:** 1.0
**Last Updated:** 2025-01-18
**Created By:** Phuong Doan

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Complete Feature List](#2-complete-feature-list)
3. [Technology Stack](#3-technology-stack)
4. [Data Models & Architecture](#4-data-models--architecture)
5. [Core Algorithms](#5-core-algorithms)
6. [API & Integrations](#6-api--integrations)
7. [Development Requirements](#7-development-requirements)
8. [Monetization Model](#8-monetization-model)
9. [Success Metrics](#9-success-metrics)

---

## 1. Project Overview

### 1.1 Vision
Build an iOS/watchOS application that transforms Apple Watch into a real-time stress monitor, using Heart Rate Variability (HRV) and heart rate data to help users understand and manage their physical stress levels.

### 1.2 Target Platforms

| Platform | Minimum Version | Notes |
|----------|-----------------|-------|
| iOS | 17.0+ | Primary app interface |
| watchOS | 9.0+ | Watch app + complications |
| iPhone | iPhone XS and newer | HealthKit capabilities |
| Apple Watch | Series 4 and newer | HRV measurement support |

### 1.3 Project Scope

```
┌─────────────────────────────────────────────────────────────────┐
│                      PROJECT SCOPE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────┐    ┌───────────────────┐                 │
│  │    iPhone App     │    │   Watch App       │                 │
│  │                   │    │                   │                 │
│  │ • Dashboard       │◄──►│ • Stress View     │                 │
│  │ • Trends/Charts   │    │ • Complications  │                 │
│  │ • Settings        │    │ • Notifications   │                 │
│  │ • Premium Features│    │ • Quick Actions   │                 │
│  └─────────┬─────────┘    └─────────┬─────────┘                 │
│            │                       │                           │
│            └───────────┬───────────┘                           │
│                        │                                       │
│                        ▼                                       │
│          ┌─────────────────────────────┐                     │
│          │      HealthKit (System)      │                     │
│          │  • HRV Data                 │                     │
│          │  • Heart Rate               │                     │
│          │  • Resting Heart Rate       │                     │
│          │  • Sleep Analysis           │                     │
│          └─────────────────────────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Complete Feature List

### 2.1 Core Features (MVP - Free Tier)

#### HRV Monitoring
| Feature | Description | Priority |
|---------|-------------|----------|
| **Today's HRV** | Display current day's HRV readings | P0 |
| **Current HRV** | Real-time HRV value with trend indicator | P0 |
| **30-Day Average** | Personal baseline calculation | P0 |
| **HRV History** | Historical HRV data access | P1 |

#### Stress Level Detection
| Feature | Description | Priority |
|---------|-------------|----------|
| **Real-time Stress** | Current stress level (5 levels) | P0 |
| **Stress Notifications** | Alerts when stress exceeds threshold | P0 |
| **Stress Trends** | Hourly, daily, weekly, monthly views | P0 |
| **Historical Data** | Past stress level access | P1 |
| **Personal Baseline** | Individualized stress standards | P0 |

#### Watch Integration
| Feature | Description | Priority |
|---------|-------------|----------|
| **Watch App** | Standalone watchOS application | P0 |
| **Complications** | Multiple watch face templates | P0 |
| **Watch Notifications** | Stress alerts on wrist | P0 |
| **Background Sync** | iPhone-Watch data synchronization | P0 |

#### Data Visualization
| Feature | Description | Priority |
|---------|-------------|----------|
| **Dashboard** | Main stress overview screen | P0 |
| **Trend Charts** | Line/bar charts for HRV & stress | P0 |
| **Stress Gauge** | Visual stress level indicator | P0 |
| **Calendar View** | Historical stress calendar | P1 |

---

### 2.2 Extended Features (Pro/Premium)

#### Sleep Tracking
| Feature | Description |
|---------|-------------|
| **Sleep Analysis** | Sleep stages and quality |
| **Sleep HRV** | HRV during sleep periods |
| **Sleep Trends** | Weekly/monthly sleep patterns |
| **Bedtime Reminders** | Smart sleep scheduling |
| **Sleep Goals** | Personalized sleep targets |

#### Wellness Tracking
| Feature | Description |
|---------|-------------|
| **Mood Logging** | Daily mood check-ins |
| **Mood Correlation** | Mood vs HRV analysis |
| **Hydration Tracking** | Water intake logging |
| **Caffeine Tracker** | Caffeine consumption & effects |
| **Exercise Zones** | Heart rate zone training |
| **Breathing Exercises** | Guided stress relief sessions |

#### Customization
| Feature | Description |
|---------|-------------|
| **Custom Themes** | Personalized color schemes |
| **Animated Characters** | Fun stress visualizations |
| **Custom Watch Faces** | Personalized complications |
| **Stress Thresholds** | Customizable alert levels |
| **Notification Schedules** | Personalized timing |

---

### 2.3 System Features

#### Data Management
| Feature | Description | Priority |
|---------|-------------|----------|
| **iCloud Sync** | Cross-device data synchronization | P0 |
| **Data Export** | CSV/PDF export functionality | P1 |
| **Data Deletion** | GDPR compliance | P0 |
| **Backup/Restore** | Data recovery options | P1 |
| **Local Storage** | Offline data access | P0 |

#### User Experience
| Feature | Description | Priority |
|---------|-------------|----------|
| **Onboarding** | First-time user flow | P0 |
| **Tutorial** | Feature walkthrough | P1 |
| **FAQ Section** | In-app help center | P1 |
| **Support Contact** | Direct support access | P1 |
| **Localization** | Multi-language support | P2 |

#### Notifications
| Feature | Description | Priority |
|---------|-------------|----------|
| **Stress Alerts** | High stress notifications | P0 |
| **Daily Summary** | Morning/evening reports | P1 |
| **Weekly Insights** | Weekly trends report | P1 |
| **Achievement Notifications** | Milestone celebrations | P1 |
| **Quiet Hours** | Do-not-disturb periods | P1 |

---

## 3. Technology Stack

### 3.1 Core Technologies

```
┌─────────────────────────────────────────────────────────────┐
│                    TECHNOLOGY STACK                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 FRONTEND LAYER                      │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Language:     Swift 5.9+                           │   │
│  │  UI Framework: SwiftUI + UIKit                     │   │
│  │  Architecture:  MVVM                               │   │
│  │  Patterns:     Combine, Async/Await                │   │
│  └─────────────────────────────────────────────────────┘   │
│                              ▲                              │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              PLATFORM SPECIFIC                       │   │
│  ├──────────────────────┬──────────────────────────────┤   │
│  │   iOS App            │   watchOS App                │   │
│  │                      │                              │   │
│  │ • SwiftUI Views      │ • SwiftUI for watchOS        │   │
│  │ • UIKit (legacy)     │ • WatchKit                  │   │
│  │ • Widgets            │ • Complications             │   │
│  │ • WidgetsExtension   │ • Background Tasks          │   │
│  └──────────────────────┴──────────────────────────────┘   │
│                              ▲                              │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 SERVICE LAYER                       │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  • HealthKit Service     (Health data access)       │   │
│  │  • Stress Algorithm      (Calculation engine)       │   │
│  │  • Notification Service (Alert scheduling)          │   │
│  │  • CloudKit Service      (iCloud sync)             │   │
│  │  • StoreKit Service      (Subscriptions)           │   │
│  └─────────────────────────────────────────────────────┘   │
│                              ▲                              │
│                              │                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 DATA LAYER                          │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Persistence:   Core Data / SwiftData               │   │
│  │  Cloud:        CloudKit Private Database           │   │
│  │  Cache:        UserDefaults + Keychain             │   │
│  │  Health Data:  HealthKit (system managed)          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Detailed Tech Stack

#### iOS App
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Language** | Swift 5.9+ | Primary development language |
| **UI Framework** | SwiftUI | Modern declarative UI |
| **UI Framework** | UIKit | Fallback for complex views |
| **Concurrency** | Async/Await | Asynchronous operations |
| **Reactive** | Combine | Data binding and streams |
| **Dependency Injection** | Manual / SwiftUI | Service management |

#### watchOS App
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | WatchKit | Watch app framework |
| **UI** | SwiftUI for watchOS | Watch interface |
| **Complications** | CLKComplication | Watch face widgets |
| **Background** | WKApplicationRefresh | Background updates |

#### Data & Storage
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Health Data** | HealthKit | System health integration |
| **Local DB** | Core Data | Structured data storage |
| **Modern Alternative** | SwiftData | Newer persistence option |
| **Cloud Sync** | CloudKit | iCloud synchronization |
| **Simple Storage** | UserDefaults | App settings |
| **Secure Storage** | Keychain Services | Sensitive data |

#### System Integration
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Notifications** | UserNotifications | Alert scheduling |
| **Background Tasks** | BackgroundTasks | Scheduled operations |
| **In-App Purchases** | StoreKit 2 | Subscriptions |
| **Widgets** | WidgetKit | Home screen widgets |
| **Siri** | AppIntents (optional) | Voice commands |

#### Development Tools
| Component | Technology | Purpose |
|-----------|------------|---------|
| **IDE** | Xcode 15+ | Development environment |
| **Version Control** | Git + GitHub | Source control |
| **CI/CD** | GitHub Actions (optional) | Automated builds |
| **Testing** | XCTest | Unit & UI tests |
| **Crash Reporting** | Firebase Crashlytics (optional) | Error tracking |

---

### 3.3 Third-Party Libraries (Optional)

| Library | Purpose | Integration |
|---------|---------|-------------|
| **Charts** | Data visualization | SwiftUI Charts (native) or DGCharts |
| **Lottie** | Complex animations | Optional for premium themes |
| **KeychainAccess** | Keychain wrapper | Simplifies secure storage |
| **CombineExt** | Combine extensions | Enhanced reactive operators |

---

## 4. Data Models & Architecture

### 4.1 Core Data Models

```swift
// MARK: - HRV Reading Model
struct HRVReading: Identifiable, Codable {
    let id: UUID
    let date: Date
    let hrvValue: Double              // SDNN in milliseconds
    let heartRate: Double?            // BPM
    let restingHeartRate: Double?     // BPM
    let source: HRVSource             // automatic, manual, watch
    let quality: MeasurementQuality   // good, fair, poor

    enum HRVSource: String, Codable {
        case automatic   // Apple Watch automatic
        case manual      // User initiated
        case watch       // Watch app request
    }

    enum MeasurementQuality: String, Codable {
        case good
        case fair
        case poor
        case unknown
    }
}

// MARK: - Stress Level Model
struct StressLevel: Identifiable, Codable {
    let id: UUID
    let date: Date
    let level: Level
    let score: Double                // -2.0 to 2.0 scale
    let hrvValue: Double
    let restingHeartRate: Double?
    let factors: [StressFactor]
    let isEstimated: Bool

    enum Level: String, Codable, CaseIterable {
        case relaxed       = "Relaxed"        // Score: < -1.5
        case normal        = "Normal"         // Score: -1.5 to -0.5
        case elevated      = "Elevated"       // Score: -0.5 to 0.5
        case highStress    = "High Stress"    // Score: 0.5 to 1.5
        case overload      = "Overload"       // Score: > 1.5
        case undefined     = "Undefined"      // Insufficient data
    }

    struct StressFactor: Codable {
        let type: FactorType
        let impact: Double          // -1.0 to 1.0

        enum FactorType: String, Codable {
            case hrvDeviation
            case rhrElevation
            case activityLevel
            case sleepQuality
            case timeOfDay
        }
    }
}

// MARK: - Personal Baseline Model
struct PersonalBaseline: Identifiable, Codable {
    let id: UUID
    let userID: String
    let averageHRV: Double          // 30-day average
    let averageRHR: Double          // 30-day average
    let hrvStandardDeviation: Double
    let rhrStandardDeviation: Double
    let sampleSize: Int             // Number of data points
    let lastUpdated: Date
    let minimumDataPoints: Int = 30 // Days needed

    var isReady: Bool {
        sampleSize >= minimumDataPoints
    }
}

// MARK: - User Settings Model
struct UserSettings: Codable {
    // General
    var notificationsEnabled: Bool
    var syncToCloud: Bool
    var darkModeEnabled: Bool

    // Stress Settings
    var stressThreshold: StressLevel.Level
    var alertOnHighStress: Bool
    var alertOnStressOverload: Bool

    // Notification Schedule
    var dailySummaryTime: Date
    var weeklyReportDay: Weekday
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date

    // Display
    var preferredTheme: AppTheme
    var showHRVInMs: Bool            // true = ms, false = SDNN
    var chartTimeRange: TimeRange

    // Subscription
    var isProSubscriber: Bool
    var subscriptionExpiry: Date?

    enum Weekday: Int, Codable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }

    enum AppTheme: String, Codable {
        case system, light, dark
    }

    enum TimeRange: Int, Codable {
        case hourly = 1, daily = 24, weekly = 168, monthly = 720
    }
}

// MARK: - Trend Data Model
struct TrendData: Identifiable {
    let id: UUID
    let date: Date
    let stressLevel: StressLevel.Level
    let hrvValue: Double
    let restingHeartRate: Double?
    let dataPoints: [DataPoint]

    struct DataPoint: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let value: Double
        let type: DataType

        enum DataType: String, Codable {
            case hrv
            case stress
            case heartRate
        }
    }
}

// MARK: - Notification Settings Model
struct NotificationSettings: Codable {
    var stressAlertsEnabled: Bool
    var dailySummaryEnabled: Bool
    var weeklyReportEnabled: Bool
    var achievementNotificationsEnabled: Bool

    var stressAlertThreshold: StressLevel.Level
    var notificationSound: String
    var hapticFeedback: Bool
}

// MARK: - Sleep Data Model (Pro Feature)
struct SleepEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bedTime: Date
    let wakeTime: Date
    let duration: TimeInterval
    let quality: SleepQuality
    let averageHRV: Double?
    let averageHeartRate: Double?

    enum SleepQuality: String, Codable {
        case excellent, good, fair, poor
    }
}

// MARK: - Mood Entry Model (Pro Feature)
struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mood: Mood
    let energyLevel: Int          // 1-5
    let stressLevel: Int          // 1-5
    let notes: String?
    let correlatedHRV: Double?

    enum Mood: String, Codable, CaseIterable {
        case veryHappy
        case happy
        case neutral
        case sad
        case verySad
        case anxious
        case stressed
        case calm
    }
}

// MARK: - Hydration Entry Model (Pro Feature)
struct HydrationEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amountML: Int
    let entryType: EntryType

    enum EntryType: String, Codable {
        case water
        case coffee
        case tea
        case soda
        case other
    }
}

// MARK: - Caffeine Entry Model (Pro Feature)
struct CaffeineEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amountMG: Int
    let source: String

    var halfLifeDecay: Double {
        // Caffeine half-life is approximately 5 hours
        let hoursPassed = Date().timeIntervalSince(date) / 3600
        return amountMG * pow(0.5, hoursPassed / 5.0)
    }
}
```

### 4.2 Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    MVVM ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    VIEW LAYER                       │   │
│  │  (SwiftUI Views)                                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │   │
│  │  │ Dashboard   │  │   Trends    │  │  Settings  │  │   │
│  │  │    View     │  │    View     │  │    View    │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘  │   │
│  └─────────┼────────────────┼────────────────┼─────────┘   │
│            │                │                │             │
│            ▼                ▼                ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  VIEWMODEL LAYER                    │   │
│  │  (ObservableObjects / @State)                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │   │
│  │  │ Dashboard   │  │   Trends    │  │  Settings  │  │   │
│  │  │ ViewModel   │  │  ViewModel  │  │ ViewModel  │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘  │   │
│  └─────────┼────────────────┼────────────────┼─────────┘   │
│            │                │                │             │
│            ▼                ▼                ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    SERVICE LAYER                    │   │
│  │  (Singleton Services)                               │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ HealthKit    │  │ Stress       │                │   │
│  │  │  Service     │  │  Algorithm   │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ CloudKit     │  │ Notification │                │   │
│  │  │  Service     │  │   Service    │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  └─────────────────────────────────────────────────────┘   │
│            │                                                │
│            ▼                                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    DATA LAYER                       │   │
│  │  • HealthKit (System Health Data)                   │   │
│  │  • Core Data (App-specific data)                    │   │
│  │  • CloudKit (Cloud synchronization)                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Key Services

```swift
// MARK: - HealthKit Service
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchHRVData(from: Date, to: Date) async throws -> [HRVReading]
    func fetchHeartRateData(from: Date, to: Date) async throws -> [HeartRateReading]
    func fetchRestingHeartRate(from: Date, to: Date) async throws -> [RestingHRReading]
    func observeHRVUpdates() -> AsyncStream<HRVReading>
}

// MARK: - Stress Calculation Service
protocol StressAlgorithmProtocol {
    func calculateStressLevel(
        hrv: Double,
        restingHeartRate: Double?,
        baseline: PersonalBaseline
    ) -> StressLevel

    func updateBaseline(
        readings: [HRVReading],
        currentBaseline: PersonalBaseline?
    ) -> PersonalBaseline

    func isDataSufficient(baseline: PersonalBaseline?) -> Bool
}

// MARK: - CloudKit Service
protocol CloudKitServiceProtocol {
    func syncToCloud() async throws
    func syncFromCloud() async throws
    func deleteAllUserData() async throws
}

// MARK: - Notification Service
protocol NotificationServiceProtocol {
    func requestAuthorization() async throws
    func scheduleStressAlert(level: StressLevel.Level)
    func scheduleDailySummary(time: Date)
    func scheduleWeeklyReport(day: Weekday)
    func cancelAllNotifications()
}

// MARK: - StoreKit Service
protocol StoreKitServiceProtocol {
    func fetchSubscriptionOptions() async throws -> [SubscriptionOption]
    func purchase(subscription: SubscriptionOption) async throws
    func restorePurchases() async throws
    func checkSubscriptionStatus() async throws -> SubscriptionStatus?
}
```

---

## 5. Core Algorithms

### 5.1 Stress Level Calculation Algorithm

```swift
// MARK: - Stress Calculation
struct StressCalculator {

    /// Calculates stress level based on HRV and resting heart rate
    /// - Parameters:
    ///   - hrv: Current HRV value in milliseconds
    ///   - restingHeartRate: Current resting heart rate in BPM (optional)
    ///   - baseline: User's personal baseline data
    /// - Returns: Calculated stress level
    func calculateStress(
        hrv: Double,
        restingHeartRate: Double?,
        baseline: PersonalBaseline
    ) -> StressLevel {

        // Check if baseline is ready
        guard baseline.isReady else {
            return StressLevel(
                date: Date(),
                level: .undefined,
                score: 0,
                hrvValue: hrv,
                restingHeartRate: restingHeartRate,
                factors: [],
                isEstimated: false
            )
        }

        // Calculate HRV deviation from personal baseline
        // Negative = lower than average (bad), Positive = higher than average (good)
        let hrvDeviation = (hrv - baseline.averageHRV) / baseline.hrvStandardDeviation

        // Calculate resting heart rate elevation
        // Positive = higher than average (bad), Negative = lower (good)
        var rhrElevation: Double = 0
        if let rhr = restingHeartRate {
            rhrElevation = (rhr - baseline.averageRHR) / baseline.rhrStandardDeviation
        }

        // Calculate combined stress score
        // HRV deviation: 60% weight (inverted, since lower is bad)
        // RHR elevation: 40% weight
        let stressScore = (-hrvDeviation * 0.6) + (rhrElevation * 0.4)

        // Determine stress level from score
        let level: StressLevel.Level
        switch stressScore {
        case ...(-1.5):
            level = .relaxed
        case (-1.5)...(-0.5):
            level = .normal
        case (-0.5)...(0.5):
            level = .elevated
        case (0.5)...(1.5):
            level = .highStress
        case (1.5)...:
            level = .overload
        default:
            level = .undefined
        }

        // Create stress factors for transparency
        let factors = [
            StressLevel.StressFactor(
                type: .hrvDeviation,
                impact: -hrvDeviation
            ),
            StressLevel.StressFactor(
                type: .rhrElevation,
                impact: rhrElevation
            )
        ]

        return StressLevel(
            date: Date(),
            level: level,
            score: stressScore,
            hrvValue: hrv,
            restingHeartRate: restingHeartRate,
            factors: factors,
            isEstimated: false
        )
    }

    /// Updates personal baseline with new readings
    /// - Parameters:
    ///   - readings: Array of HRV readings
    ///   - currentBaseline: Existing baseline (nil for new users)
    /// - Returns: Updated personal baseline
    func updateBaseline(
        readings: [HRVReading],
        currentBaseline: PersonalBaseline?
    ) -> PersonalBaseline {

        // Filter readings from last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentReadings = readings.filter { $0.date >= thirtyDaysAgo && $0.quality != .poor }

        guard !recentReadings.isEmpty else {
            // No data available, return default baseline
            return PersonalBaseline(
                id: UUID(),
                userID: "current",
                averageHRV: 50,      // Default average HRV
                averageRHR: 70,      // Default resting HR
                hrvStandardDeviation: 15,
                rhrStandardDeviation: 5,
                sampleSize: 0,
                lastUpdated: Date()
            )
        }

        // Calculate statistics
        let hrvValues = recentReadings.map { $0.hrvValue }
        let rhrValues = recentReadings.compactMap { $0.restingHeartRate }

        let avgHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)

        let avgRHR: Double
        if !rhrValues.isEmpty {
            avgRHR = rhrValues.reduce(0, +) / Double(rhrValues.count)
        } else {
            avgRHR = currentBaseline?.averageRHR ?? 70
        }

        // Calculate standard deviations
        let hrvVariance = hrvValues.map { pow($0 - avgHRV, 2) }.reduce(0, +) / Double(hrvValues.count)
        let hrvStdDev = sqrt(hrvVariance)

        let rhrVariance = rhrValues.map { pow($0 - avgRHR, 2) }.reduce(0, +) / Double(rhrValues.count)
        let rhrStdDev = rhrValues.isEmpty ? 5 : sqrt(rhrVariance)

        return PersonalBaseline(
            id: currentBaseline?.id ?? UUID(),
            userID: "current",
            averageHRV: avgHRV,
            averageRHR: avgRHR,
            hrvStandardDeviation: hrvStdDev,
            rhrStandardDeviation: rhrStdDev,
            sampleSize: recentReadings.count,
            lastUpdated: Date()
        )
    }
}
```

### 5.2 Real-time Stress Update Algorithm

```swift
// MARK: - Real-time Stress Calculator
struct RealTimeStressCalculator {

    /// Calculates real-time stress level
    /// Updates every 6 minutes based on recent heart rate and HRV history
    /// - Parameters:
    ///   - recentHRV: Recent HRV readings (last few hours)
    ///   - recentHeartRate: Recent heart rate data
    ///   - baseline: User's personal baseline
    /// - Returns: Current real-time stress level
    func calculateRealTimeStress(
        recentHRV: [HRVReading],
        recentHeartRate: [HeartRateReading],
        baseline: PersonalBaseline
    ) -> StressLevel? {

        // Need at least one HRV reading from last hour
        guard let latestHRV = recentHRV.last,
              Date().timeIntervalSince(latestHRV.date) < 3600 else {
            return nil
        }

        // Calculate average heart rate from last 10 minutes
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        let recentHeartRates = recentHeartRate.filter { $0.date >= tenMinutesAgo }
        let avgHeartRate = recentHeartRates.isEmpty ? nil : recentHeartRates.map { $0.rate }.reduce(0, +) / Double(recentHeartRates.count)

        // Estimate resting heart rate
        let estimatedRHR = estimateRestingHeartRate(
            currentHeartRate: avgHeartRate,
            heartRateHistory: recentHeartRate,
            baseline: baseline
        )

        // Calculate stress using main algorithm
        return StressCalculator().calculateStress(
            hrv: latestHRV.hrvValue,
            restingHeartRate: estimatedRHR,
            baseline: baseline
        )
    }

    /// Estimates current resting heart rate from active heart rate
    private func estimateRestingHeartRate(
        currentHeartRate: Double?,
        heartRateHistory: [HeartRateReading],
        baseline: PersonalBaseline
    ) -> Double? {

        guard let current = currentHeartRate else { return nil }

        // If heart rate is close to baseline RHR, consider it resting
        let deviationFromBaseline = abs(current - baseline.averageRHR)

        if deviationFromBaseline < 10 {
            // Heart rate is close to resting baseline
            return current
        }

        // Heart rate is elevated - estimate what resting would be
        // Look for lowest heart rate in recent history
        let lowestRecent = heartRateHistory.map { $0.rate }.min()

        return lowestRecent ?? baseline.averageRHR
    }
}
```

---

## 6. API & Integrations

### 6.1 HealthKit Integration

```swift
// MARK: - HealthKit Configuration
struct HealthKitConfiguration {

    static let healthTypesToRead: Set<HKObjectType> = [
        // HRV Data
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,

        // Heart Rate Data
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,

        // Sleep Data (Pro feature)
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,

        // Workout Data
        HKObjectType.workoutType()
    ]

    static let healthTypesToWrite: Set<HKSampleType> = [
        // Optionally write stress levels as health data
        // (consider if appropriate for app model)
    ]
}

// MARK: - HealthKit Query Manager
class HealthKitQueryManager {

    private let healthStore = HKHealthStore()

    /// Query HRV data for a date range
    func queryHRVData(from startDate: Date, to endDate: Date) async throws -> [HRVReading] {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let readings = samples?.compactMap { sample -> HRVReading? in
                    guard let sample = sample as? HKQuantitySample else { return nil }
                    return HRVReading(
                        id: UUID(),
                        date: sample.startDate,
                        hrvValue: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                        heartRate: nil,
                        restingHeartRate: nil,
                        source: .automatic,
                        quality: .good
                    )
                } ?? []

                continuation.resume(returning: readings)
            }

            healthStore.execute(query)
        }
    }

    /// Set up background HRV delivery
    func observeHRVUpdates() -> AsyncStream<HRVReading> {
        return AsyncStream { continuation in
            let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

            let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { _, _, error in
                if let error = error {
                    continuation.finish()
                    return
                }

                // Fetch new data and yield to stream
                Task {
                    do {
                        let now = Date()
                        let fiveMinutesAgo = now.addingTimeInterval(-300)
                        let newReadings = try await self.queryHRVData(from: fiveMinutesAgo, to: now)

                        for reading in newReadings {
                            continuation.yield(reading)
                        }
                    } catch {
                        continuation.finish()
                    }
                }
            }

            healthStore.execute(query)

            continuation.onTermination = { @Sendable [weak self] _ in
                self?.healthStore.stop(query)
            }
        }
    }
}
```

### 6.2 CloudKit Integration

```swift
// MARK: - CloudKit Schema
struct CloudKitSchema {

    // Zone Configuration
    static let zoneID = CKRecordZone.ID(zoneName: "StressMonitorZone", ownerName: CKCurrentUserDefaultName)

    // Record Types
    static let recordTypes = [
        "CD_HRVReading": [
            "date": .date,
            "hrvValue": .double,
            "heartRate": .double,
            "quality": .string
        ],
        "CD_StressLevel": [
            "date": .date,
            "level": .string,
            "score": .double,
            "hrvValue": .double,
            "factors": .data
        ],
        "CD_PersonalBaseline": [
            "averageHRV": .double,
            "averageRHR": .double,
            "hrvStdDev": .double,
            "rhrStdDev": .double,
            "sampleSize": .int64,
            "lastUpdated": .date
        ],
        "CD_UserSettings": [
            "notificationsEnabled": .bool,
            "syncToCloud": .bool,
            "stressThreshold": .string,
            "jsonData": .data
        ]
    ]
}

// MARK: - CloudKit Sync Manager
class CloudKitSyncManager {

    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase

    init() {
        self.privateDatabase = container.privateCloudDatabase
    }

    /// Sync HRV reading to CloudKit
    func syncHRVReading(_ reading: HRVReading) async throws {
        let recordID = CKRecord.ID(recordName: reading.id.uuidString, zoneID: CloudKitSchema.zoneID)

        let record = CKRecord(recordType: "CD_HRVReading", recordID: recordID)
        record["date"] = reading.date
        record["hrvValue"] = reading.hrvValue
        record["heartRate"] = reading.heartRate
        record["quality"] = reading.quality.rawValue

        try await privateDatabase.save(record)
    }

    /// Sync user settings to CloudKit
    func syncUserSettings(_ settings: UserSettings) async throws {
        let recordID = CKRecord.ID(recordName: "UserSettings", zoneID: CloudKitSchema.zoneID)

        let record = CKRecord(recordType: "CD_UserSettings", recordID: recordID)
        record["notificationsEnabled"] = settings.notificationsEnabled
        record["syncToCloud"] = settings.syncToCloud
        record["stressThreshold"] = settings.stressThreshold.rawValue

        let encoder = JSONEncoder()
        record["jsonData"] = try encoder.encode(settings)

        try await privateDatabase.save(record)
    }

    /// Delete all user data from CloudKit (GDPR)
    func deleteAllUserData() async throws {
        // Delete all records in the custom zone
        let zone = CKRecordZone.ID(zoneName: "StressMonitorZone", ownerName: CKCurrentUserDefaultName)

        let operation = CKModifyRecordZonesOperation(recordZonesToDelete: [zone])
        try await operation.start()
    }
}
```

### 6.3 Notification Integration

```swift
// MARK: - Notification Manager
class NotificationManager {

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Request notification authorization
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await notificationCenter.requestAuthorization(options: options)
    }

    /// Schedule stress alert notification
    func scheduleStressAlert(level: StressLevel.Level, currentHRV: Double) {
        let content = UNMutableNotificationContent()

        switch level {
        case .relaxed, .normal:
            return // Don't notify for normal levels
        case .elevated:
            content.title = "Stress Level Elevated"
            content.body = "Your stress level is slightly elevated. Consider taking a short break."
            content.sound = .default
        case .highStress:
            content.title = "High Stress Detected"
            content.body = "Your stress level is high. Take a moment to breathe and relax."
            content.sound = .critical
        case .overload:
            content.title = "⚠️ Stress Overload"
            content.body = "Your stress level is very high. Please prioritize rest and recovery."
            content.sound = .critical
            content.categoryIdentifier = "STRESS_OVERLOAD"
        case .undefined:
            return
        }

        content.badge = 1

        // Trigger immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    /// Schedule daily summary notification
    func scheduleDailySummary(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Stress Summary"
        content.body = "Check your stress trends for today."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    /// Register notification categories (for actions)
    func registerCategories() {
        let relaxAction = UNNotificationAction(
            identifier: "RELAX_ACTION",
            title: "Start Breathing",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: "STRESS_OVERLOAD",
            actions: [relaxAction],
            intentIdentifiers: []
        )

        notificationCenter.setNotificationCategories([category])
    }
}
```

---

## 7. Development Requirements

### 7.1 Development Environment

| Requirement | Minimum Version | Recommended Version |
|-------------|-----------------|---------------------|
| **macOS** | Sonoma (14.0+) | Sonoma (14.5+) |
| **Xcode** | 15.0+ | 15.3+ |
| **Swift** | 5.9+ | 5.10+ |
| **iOS SDK** | iOS 17.0+ | iOS 17.2+ |
| **watchOS SDK** | watchOS 10.0+ | watchOS 10.2+ |

### 7.2 Hardware Requirements

**For Development:**
- Mac with Apple Silicon (M1/M2/M3) or Intel-based Mac
- At least 16GB RAM recommended
- 50GB+ free disk space

**For Testing:**
- iPhone XS or newer (iOS 17+ compatible)
- Apple Watch Series 4 or newer (watchOS 9+ compatible)

### 7.3 Apple Developer Requirements

| Item | Requirement |
|------|-------------|
| **Apple Developer Account** | Required for App Store distribution |
| **Team ID** | For code signing and provisioning |
| **App ID** | Bundle identifier registration |
| **Capabilities** | HealthKit, CloudKit, Background Modes, Notifications, In-App Purchase |
| **Certificates** | Development and Distribution certificates |
| **Provisioning Profiles** | For iOS and watchOS targets |

### 7.4 Required Capabilities

```xml
<!-- Entitlements file -->
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
<key>com.apple.developer.healthkit.background-delivery</key>
<array/>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourcompany.StressMonitor</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>com.yourcompany.StressMonitor.premium</string>
</array>
<key>com.apple.developer.background-modes</key>
<array>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

### 7.5 Info.plist Configuration

```xml
<!-- iOS Info.plist -->
<key>NSHealthShareUsageDescription</key>
<string>StressMonitor needs access to your health data to calculate stress levels from HRV and heart rate measurements.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>StressMonitor will save stress analysis to your health records.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>StressMonitor sends notifications when your stress levels are elevated.</string>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

---

## 8. Monetization Model

### 8.1 Freemium Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    MONETIZATION MODEL                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐      ┌─────────────────────┐     │
│  │      FREE TIER      │      │     PRO TIER        │     │
│  │    (Core Features)  │      │  (Premium Features) │     │
│  ├─────────────────────┤      ├─────────────────────┤     │
│  │ • Today's HRV       │      │ • All Free Features │     │
│  │ • Current HRV       │      │                     │     │
│  │ • Real-time Stress  │      │ • Sleep Analysis    │     │
│  │ • Stress Trends     │      │ • Mood Tracking     │     │
│  │ • Historical Data   │      │ • Hydration Track   │     │
│  │ • Watch App         │      │ • Caffeine Track    │     │
│  │ • Complications    │      │ • Breathing Guide   │     │
│  │ • Basic Themes      │      │ • Custom Themes     │     │
│  │ • iCloud Sync       │      │ • Advanced Charts   │     │
│  │                     │      │ • Priority Support  │     │
│  │                     │      │ • No Ads            │     │
│  └─────────────────────┘      └─────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Subscription Pricing

| Tier | Price | Billing Period | Features |
|------|-------|----------------|----------|
| **Free** | $0 | - | Core HRV and stress monitoring |
| **Monthly** | $4.99/mo | Monthly | All premium features |
| **Yearly** | $29.99/yr | Yearly | All premium features (~50% savings) |

### 8.3 StoreKit Product IDs

```swift
enum SubscriptionProduct: String, CaseIterable {
    case monthlyPremium = "com.yourcompany.StressMonitor.premium.monthly"
    case yearlyPremium = "com.yourcompany.StressMonitor.premium.yearly"

    var localizedTitle: String {
        switch self {
        case .monthlyPremium: return "Monthly Premium"
        case .yearlyPremium: return "Yearly Premium"
        }
    }

    var price: Decimal {
        // Retrieved from App Store Connect
        return 0
    }
}
```

### 8.4 Free vs Pro Feature Matrix

| Feature | Free | Pro |
|---------|------|-----|
| Today's HRV | ✅ | ✅ |
| Current HRV | ✅ | ✅ |
| Real-time Stress | ✅ | ✅ |
| Stress Trends (7 days) | ✅ | ✅ |
| Historical Data | ✅ | ✅ |
| Watch App | ✅ | ✅ |
| Complications | ✅ | ✅ |
| Basic Themes | ✅ | ✅ |
| iCloud Sync | ✅ | ✅ |
| --- | --- | --- |
| Sleep Analysis | ❌ | ✅ |
| Mood Tracking | ❌ | ✅ |
| Hydration Tracking | ❌ | ✅ |
| Caffeine Tracking | ❌ | ✅ |
| Breathing Exercises | ❌ | ✅ |
| Workout Zones | ❌ | ✅ |
| Custom Themes | ❌ | ✅ |
| Extended Trends (30+ days) | ❌ | ✅ |
| Data Export | ❌ | ✅ |
| Priority Support | ❌ | ✅ |

---

## 9. Success Metrics

### 9.1 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **App Store Approval** | ✅ Pass Review | First submission |
| **Crash-Free Rate** | > 99.5% | Firebase Crashlytics |
| **App Launch Time** | < 2 seconds | Performance testing |
| **Battery Impact** | < 2%/day | Battery testing |
| **Background Sync Success** | > 95% | CloudKit analytics |

### 9.2 User Metrics

| Metric | 1 Month | 3 Months | 6 Months |
|--------|---------|----------|----------|
| **Downloads** | 100 | 1,000 | 5,000 |
| **Active Users (DAU)** | 20 | 200 | 1,000 |
| **Retention (D30)** | 25% | 30% | 35% |
| **App Store Rating** | 4.0+ | 4.5+ | 4.5+ |
| **Reviews** | 10 | 50 | 200 |

### 9.3 Business Metrics

| Metric | 3 Months | 6 Months | 12 Months |
|--------|----------|----------|-----------|
| **Free Users** | 500 | 3,000 | 15,000 |
| **Pro Subscribers** | 25 | 200 | 1,200 |
| **Conversion Rate** | 5% | 7% | 8% |
| **Monthly Revenue (MRR)** | $125 | $1,400 | $8,400 |
| **Annual Revenue (ARR)** | $1,500 | $16,800 | $100,800 |

### 9.4 Engagement Metrics

| Metric | Target | Description |
|--------|--------|-------------|
| **Daily Active Rate** | > 20% | Users opening app daily |
| **Weekly Active Rate** | > 40% | Users opening app weekly |
| **Watch App Usage** | > 60% | Pro users using watch app |
| **Complication Adds** | > 50% | Users adding complications |
| **Feature Usage** | > 3/week | Avg features used per user |

---

## 10. Appendix

### 10.1 Stress Level Color Scheme

```swift
enum StressLevelColor {
    static let relaxed = Color.green
    static let normal = Color.blue
    static let elevated = Color.yellow
    static let highStress = Color.orange
    static let overload = Color.red
    static let undefined = Color.gray

    static func color(for level: StressLevel.Level) -> Color {
        switch level {
        case .relaxed: return relaxed
        case .normal: return normal
        case .elevated: return elevated
        case .highStress: return highStress
        case .overload: return overload
        case .undefined: return undefined
        }
    }
}
```

### 10.2 Supported Localizations

| Language | Code | Priority |
|----------|------|----------|
| English | en | P0 |
| Spanish | es | P1 |
| French | fr | P1 |
| German | de | P2 |
| Italian | it | P2 |
| Portuguese | pt | P2 |
| Japanese | ja | P2 |
| Korean | ko | P2 |
| Chinese (Simplified) | zh-Hans | P2 |
| Chinese (Traditional) | zh-Hant | P2 |
| Arabic | ar | P3 |

### 10.3 App Store Screenshots Required

| Device Type | Sizes Required |
|-------------|----------------|
| iPhone 6.7" | 1290 x 2796 |
| iPhone 6.5" | 1242 x 2688 |
| iPhone 5.5" | 1242 x 2208 |
| Apple Watch | - |

Minimum 3 screenshots per device type.

---

**Document End**

---

*This project summary provides a comprehensive overview of all features, technology stack, data models, algorithms, and requirements for building a stress monitoring application similar to StressWatch. Use this document as the primary reference throughout the development lifecycle.*

**Next Steps:**
1. Set up Xcode project structure
2. Configure Apple Developer account and capabilities
3. Create UI/UX mockups
4. Begin Phase 1 implementation
