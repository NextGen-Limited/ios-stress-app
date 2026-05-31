import SwiftUI

/// Compact badge showing the reliability of the current stress score.
/// Shown near the stress score on the dashboard.
struct DataQualityBadge: View {
    let qualityInfo: DataQualityInfo

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(qualityInfo.qualityLevel.rawValue.capitalized)
                .font(.caption2)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Data quality: \(qualityInfo.qualityLevel.rawValue)")
        .accessibilityHint("\(qualityInfo.activeFactors.count) of 5 factors active")
    }

    private var iconName: String {
        switch qualityInfo.qualityLevel {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .limited: return "exclamationmark.circle"
        case .minimal: return "exclamationmark.triangle"
        }
    }

    private var backgroundColor: Color {
        switch qualityInfo.qualityLevel {
        case .excellent: return .green
        case .good: return .blue
        case .limited: return .yellow
        case .minimal: return .orange
        }
    }

    private var foregroundColor: Color { backgroundColor }
}

// MARK: - Preview

#Preview("DataQualityBadge") {
    VStack(spacing: 12) {
        DataQualityBadge(qualityInfo: DataQualityInfo(
            activeFactors: ["hrv", "heartRate", "sleep", "activity", "recovery"],
            missingFactors: [],
            dataCompleteness: 1.0,
            isCalibrated: true,
            lastCalibrationDate: Date()
        ))
        DataQualityBadge(qualityInfo: DataQualityInfo(
            activeFactors: ["hrv", "heartRate", "sleep"],
            missingFactors: ["activity", "recovery"],
            dataCompleteness: 0.75,
            isCalibrated: false,
            lastCalibrationDate: nil
        ))
        DataQualityBadge(qualityInfo: DataQualityInfo(
            activeFactors: ["hrv", "heartRate"],
            missingFactors: ["sleep", "activity", "recovery"],
            dataCompleteness: 0.55,
            isCalibrated: false,
            lastCalibrationDate: nil
        ))
        DataQualityBadge(qualityInfo: DataQualityInfo(
            activeFactors: ["hrv"],
            missingFactors: ["heartRate", "sleep", "activity", "recovery"],
            dataCompleteness: 0.40,
            isCalibrated: false,
            lastCalibrationDate: nil
        ))
    }
    .padding()
}
