import SwiftUI

/// 5-tier stress category — single source of truth for the watch app.
///
/// Aligned exactly with the iOS app's `StressCategory` and the iOS Design
/// System v1.4.2 stress scale. Every usage is paired with a numeric score
/// and a glyph so colour is never the only encoding (WCAG).
///
/// | Tier      | Score range | Hex       | Glyph |
/// |-----------|-------------|-----------|-------|
/// | Relaxed   | 0–25        | `#00A000` | ◌     |
/// | Mild      | 26–50       | `#007AFF` | ◎     |
/// | Moderate  | 51–75       | `#8A5A00` | ◐     |
/// | High      | 76–100      | `#B25400` | ◑     |
/// | Severe    | 100+        | `#FF3B30` | ●     |
public enum StressCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case relaxed
    case mild
    case moderate
    case high
    case severe

    public var id: String { rawValue }

    // MARK: - Dual Coding: Colour

    /// Primary colour for this stress category (light set, mirrored from
    /// the iOS app's `StressCategory.color`).
    public var color: Color {
        switch self {
        case .relaxed:  return Color(hex: "#00A000")
        case .mild:     return Color(hex: "#007AFF")
        case .moderate: return Color(hex: "#8A5A00")
        case .high:     return Color(hex: "#B25400")
        case .severe:   return Color(hex: "#FF3B30")
        }
    }

    /// Text colour that passes WCAG AA against light surfaces.  Moderate
    /// yellow needs a darker ink; the other tiers reuse their own colour.
    public var inkColor: Color {
        switch self {
        case .moderate: return Color(hex: "#B59400")
        default:        return color
        }
    }

    // MARK: - Dual Coding: Glyph + Icon

    /// Geometric glyph used in tier labels (always paired with the colour).
    public var glyph: String {
        switch self {
        case .relaxed:  return "◌"
        case .mild:     return "◎"
        case .moderate: return "◐"
        case .high:     return "◑"
        case .severe:   return "●"
        }
    }

    /// SF Symbol icon for this stress category.
    public var icon: String {
        switch self {
        case .relaxed:  return "leaf.fill"
        case .mild:     return "circle.fill"
        case .moderate: return "triangle.fill"
        case .high:     return "square.fill"
        case .severe:   return "exclamationmark.octagon.fill"
        }
    }

    // MARK: - Display

    /// Capitalised display name ("Relaxed", "Mild", …) for tier labels.
    public var displayName: String {
        switch self {
        case .relaxed:  return "Relaxed"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .severe:   return "Severe"
        }
    }

    /// Short label combining the glyph and name ("◌ Relaxed").
    public var glyphLabel: String { "\(glyph) \(displayName)" }

    /// Score range (inclusive lower, exclusive upper except severe).
    public var scoreRange: ClosedRange<Double> {
        switch self {
        case .relaxed:  return 0...25
        case .mild:     return 26...50
        case .moderate: return 51...75
        case .high:     return 76...100
        case .severe:   return 100...150
        }
    }

    // MARK: - Pattern / Accessibility

    public var pattern: String {
        switch self {
        case .relaxed:  return "solid fill"
        case .mild:     return "diagonal lines"
        case .moderate: return "dots pattern"
        case .high:     return "crosshatch"
        case .severe:   return "solid warning"
        }
    }

    public var accessibilityDescription: String {
        "\(displayName) stress level, represented by \(icon) icon with \(pattern)"
    }

    public func accessibilityValue(level: Double) -> String {
        "\(Int(level)) out of 100, \(displayName) stress"
    }

    // MARK: - Resolution

    /// Resolve the tier from a raw 0–100+ stress level.
    public static func category(for level: Double) -> StressCategory {
        switch level {
        case ..<26:    return .relaxed
        case ..<51:    return .mild
        case ..<76:    return .moderate
        case 76...100: return .high
        default:       return .severe   // 100+ overflow → Severe
        }
    }
}

// MARK: - Stress Source

/// Represents a stress source with name, percentage, and colour.
struct StressSource: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}
