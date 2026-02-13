import SwiftUI

public enum StressCategory: String, CaseIterable, Codable, Sendable {
    case relaxed
    case mild
    case moderate
    case high

    // MARK: - Dual Coding: Color

    /// Primary color for this stress category (WCAG AA compliant)
    public var color: Color {
        switch self {
        case .relaxed:
            return Color(light: Color(hex: "#34C759"), dark: Color(hex: "#30D158"))
        case .mild:
            return Color(light: Color(hex: "#007AFF"), dark: Color(hex: "#0A84FF"))
        case .moderate:
            return Color(hex: "#FFD60A")
        case .high:
            return Color(light: Color(hex: "#FF9500"), dark: Color(hex: "#FF9F0A"))
        }
    }

    // MARK: - Dual Coding: Icon

    /// SF Symbol icon for this stress category
    public var icon: String {
        switch self {
        case .relaxed: return "leaf.fill"
        case .mild: return "circle.fill"
        case .moderate: return "triangle.fill"
        case .high: return "square.fill"
        }
    }

    // MARK: - Dual Coding: Pattern Description

    /// Accessibility pattern description for color-blind users
    public var pattern: String {
        switch self {
        case .relaxed: return "solid fill"
        case .mild: return "diagonal lines"
        case .moderate: return "dots pattern"
        case .high: return "crosshatch"
        }
    }

    // MARK: - Accessibility

    /// VoiceOver description combining all dual coding elements
    /// Note: displayName is defined in Badge.swift extension
    public var accessibilityDescription: String {
        let name = rawValue.capitalized
        return "\(name) stress level, represented by \(icon) icon with \(pattern)"
    }

    /// Accessibility hint for interactive stress indicators
    public var accessibilityHint: String {
        "Stress category indicator"
    }

    /// Accessibility value for stress level indicators
    /// - Parameter level: Stress level from 0-100
    public func accessibilityValue(level: Double) -> String {
        let name = rawValue.capitalized
        return "\(Int(level)) out of 100, \(name) stress"
    }
}
