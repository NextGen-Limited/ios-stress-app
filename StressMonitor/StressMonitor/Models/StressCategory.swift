import SwiftUI

public enum StressCategory: String, CaseIterable, Codable, Sendable {
    case relaxed
    case mild
    case moderate
    case high

    public var color: Color {
        switch self {
        case .relaxed: return .green
        case .mild: return .blue
        case .moderate: return .yellow
        case .high: return .orange
        }
    }

    public var icon: String {
        switch self {
        case .relaxed: return "face.smiling"
        case .mild: return "face.dashed"
        case .moderate: return "wave.circle"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
}
