import SwiftUI

/// Reusable card component for displaying no data states
/// Used for individual metrics like HRV, Heart Rate, etc.
struct NoDataCard: View {
    let dataType: DataType
    let onAction: () -> Void

    enum DataType: String, CaseIterable {
        case hrv
        case heartRate
        case stress
        case timeline

        var icon: String {
            switch self {
            case .hrv: return "heart.circle"
            case .heartRate: return "waveform.path.ecg"
            case .stress: return "brain.head.profile"
            case .timeline: return "clock"
            }
        }

        var title: String {
            switch self {
            case .hrv: return "No HRV Data"
            case .heartRate: return "No Heart Rate Data"
            case .stress: return "No Stress Data"
            case .timeline: return "No Timeline Data"
            }
        }

        var description: String {
            switch self {
            case .hrv: return "HRV data will appear here after your first measurement."
            case .heartRate: return "Heart rate data will sync from Apple Watch."
            case .stress: return "Measure stress to see your patterns here."
            case .timeline: return "Timeline will populate as you take measurements."
            }
        }

        var actionTitle: String {
            switch self {
            case .hrv, .heartRate, .stress: return "Measure Now"
            case .timeline: return "Get Started"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: dataType.icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.oledTextSecondary)
                .accessibilityHidden(true)

            // Text content
            VStack(spacing: 6) {
                Text(dataType.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(dataType.description)
                    .font(.caption)
                    .foregroundColor(.oledTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action button
            Button(action: onAction) {
                Text(dataType.actionTitle)
                    .font(.subheadline.bold())
                    .foregroundColor(.primaryBlue)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.oledCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dataType.title). \(dataType.description)")
        .accessibilityHint("Double tap to \(dataType.actionTitle.lowercased())")
    }
}

// MARK: - Preview

#Preview("All No Data Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(NoDataCard.DataType.allCases, id: \.self) { type in
                NoDataCard(dataType: type, onAction: {})
            }
        }
        .padding()
    }
    .background(Color.oledBackground)
}
