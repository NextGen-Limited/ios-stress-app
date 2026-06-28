import Foundation

// MARK: - WorkoutZone

/// Five-band heart-rate zones based on a percentage of maximum heart rate.
///
/// Uses the common 50/60/70/80/90 % of `maxHR` (default formula
/// `220 - age`) breakdown:
///
/// | Zone | % of max HR | Description |
/// |------|-------------|-------------|
/// | 1    | 50–60 %     | Recovery    |
/// | 2    | 60–70 %     | Endurance   |
/// | 3    | 70–80 %     | Tempo       |
/// | 4    | 80–90 %     | Threshold   |
/// | 5    | 90–100 %    | Max         |
enum WorkoutZone: Int, CaseIterable, Sendable {
    case zone1 = 1
    case zone2
    case zone3
    case zone4
    case zone5

    /// Human-readable name ("Zone 1" ... "Zone 5").
    var displayName: String { "Zone \(rawValue)" }

    /// Training description for this band.
    var description: String {
        switch self {
        case .zone1: return "Recovery"
        case .zone2: return "Endurance"
        case .zone3: return "Tempo"
        case .zone4: return "Threshold"
        case .zone5: return "Max"
        }
    }

    /// Lower/upper bound as a fraction of max HR (0.0–1.0).
    var maxHRRatioRange: ClosedRange<Double> {
        switch self {
        case .zone1: return 0.50 ... 0.60
        case .zone2: return 0.60 ... 0.70
        case .zone3: return 0.70 ... 0.80
        case .zone4: return 0.80 ... 0.90
        case .zone5: return 0.90 ... 1.00
        }
    }

    /// Concrete BPM range for a given maximum heart rate.
    func heartRateRange(maxHR: Double = 190) -> ClosedRange<Double> {
        let bounds = maxHRRatioRange
        return (maxHR * bounds.lowerBound) ... (maxHR * bounds.upperBound)
    }

    /// Canonical token name (matches `WatchDesignTokens` colour philosophy).
    /// Values resolve to hex used by the workout view.
    var colorHex: String {
        switch self {
        case .zone1: return "#34C759" // relaxed green
        case .zone2: return "#007AFF" // endurance blue
        case .zone3: return "#FFD60A" // tempo yellow
        case .zone4: return "#FF9500" // threshold orange
        case .zone5: return "#FF3B30" // max red
        }
    }

    /// Resolve the zone containing a heart-rate value for the supplied max HR.
    static func zone(for hr: Double, maxHR: Double = 190) -> WorkoutZone {
        let ratio = maxHR > 0 ? hr / maxHR : 0
        switch ratio {
        case ..<0.60: return .zone1
        case ..<0.70: return .zone2
        case ..<0.80: return .zone3
        case ..<0.90: return .zone4
        default:      return .zone5
        }
    }

    /// Returns `true` when `hr` falls within this zone for the given max HR.
    func contains(hr: Double, maxHR: Double = 190) -> Bool {
        Self.zone(for: hr, maxHR: maxHR) == self
    }
}

// MARK: - WorkoutReading

/// A single point-in-time heart-rate sample tagged with its zone.
struct WorkoutReading: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let heartRate: Double
    let zone: WorkoutZone
}
