import Foundation
import HealthKit

/// Represents a workout or physical activity from HealthKit,
/// used for correlation with stress data in the history timeline.
struct ActivityWorkout: Identifiable {
    let id: UUID
    let name: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let calories: Double?
    let averageHeartRate: Double?
    let activityType: HKWorkoutActivityType

    var timeRange: ClosedRange<Date> {
        startDate...endDate
    }

    /// Icon name for SF Symbols
    var icon: String {
        switch activityType {
        case .running:           return "figure.run"
        case .walking:           return "figure.walk"
        case .cycling:           return "bicycle"
        case .swimming:          return "figure.pool.swim"
        case .yoga:              return "figure.mind.and.body"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "dumbbell.fill"
        case .dance:             return "figure.dance"
        case .hiking:            return "figure.hiking"
        case .elliptical:        return "elliptical.machine"
        case .rowing:            return "figure.rowing"
        case .cooldown:          return "figure.cooldown"
        default:                 return "figure.mixed.cardio"
        }
    }

    /// Short display name
    var displayName: String {
        switch activityType {
        case .running:           return "Running"
        case .walking:           return "Walking"
        case .cycling:           return "Cycling"
        case .swimming:          return "Swimming"
        case .yoga:              return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        case .functionalStrengthTraining:    return "Strength"
        case .traditionalStrengthTraining:   return "Weights"
        case .dance:             return "Dance"
        case .hiking:            return "Hiking"
        case .elliptical:        return "Elliptical"
        case .rowing:            return "Rowing"
        case .cooldown:          return "Cooldown"
        default:                 return "Workout"
        }
    }

    /// Init from HKWorkout
    init(workout: HKWorkout) {
        self.id = workout.uuid
        self.activityType = workout.workoutActivityType
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.duration = workout.duration
        self.calories = workout.totalEnergyBurned?
            .doubleValue(for: .kilocalorie())
        self.averageHeartRate = workout.metadata?[HKMetadataKeyAverageMETs]
            .flatMap { ($0 as? HKQuantity)?.doubleValue(for: .count().unitDivided(by: .minute())) }
        self.name = workout.workoutActivityType.name
    }
}

// MARK: - Correlation Data

/// Represents a correlation between an activity and surrounding stress levels.
struct StressActivityCorrelation: Identifiable {
    let id = UUID()
    let workout: ActivityWorkout
    let stressBefore: Double      // avg stress 0-30min before workout
    let stressDuring: Double      // avg stress during workout window
    let stressAfter: Double       // avg stress 0-30min after workout
    let stressChange: Double      // after - before (negative = stress decreased)
    let hrvBefore: Double
    let hrvDuring: Double
    let hrvAfter: Double

    /// Whether the workout appears to have helped reduce stress
    var isStressRelieving: Bool {
        stressChange < -0.05
    }

    /// Whether the workout appears to have increased stress
    var isStressInducing: Bool {
        stressChange > 0.05
    }

    /// Trend description
    var trendDescription: String {
        if isStressRelieving {
            return "Stress decreased after activity"
        } else if isStressInducing {
            return "Stress increased after activity"
        }
        return "Stress remained stable"
    }

    var trendIcon: String {
        if isStressRelieving { return "arrow.down.circle.fill" }
        if isStressInducing  { return "arrow.up.circle.fill" }
        return "minus.circle.fill"
    }

    var trendColor: String {
        if isStressRelieving { return "green" }
        if isStressInducing  { return "red" }
        return "secondary"
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running:           return "Running"
        case .walking:           return "Walking"
        case .cycling:           return "Cycling"
        case .swimming:          return "Swimming"
        case .yoga:              return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        case .functionalStrengthTraining:    return "Strength"
        case .traditionalStrengthTraining:   return "Weights"
        case .dance:             return "Dance"
        case .hiking:            return "Hiking"
        case .elliptical:        return "Elliptical"
        case .rowing:            return "Rowing"
        case .cooldown:          return "Cooldown"
        default:                 return "Workout"
        }
    }
}

// MARK: - Daily Summary

/// Aggregated stress + activity summary for a single day.
struct DailyStressSummary: Identifiable {
    let id = Date()
    let date: Date
    let averageStress: Double
    let peakStress: Double
    let lowestStress: Double
    let averageHRV: Double
    let readingCount: Int
    let workouts: [ActivityWorkout]
    let correlations: [StressActivityCorrelation]

    var stressCategory: HRVAnalyzer.StressCategory {
        switch averageStress {
        case 0.0..<0.2:  return .resting
        case 0.2..<0.4:  return .low
        case 0.4..<0.6:  return .moderate
        case 0.6..<0.8:  return .high
        default:          return .veryHigh
        }
    }

    var workoutCount: Int { workouts.count }

    var totalWorkoutMinutes: Int {
        Int(workouts.reduce(0) { $0 + $1.duration } / 60)
    }

    var hasData: Bool { readingCount > 0 }
}
