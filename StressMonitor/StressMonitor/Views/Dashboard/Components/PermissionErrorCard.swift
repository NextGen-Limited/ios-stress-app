import SwiftUI
import HealthKit

/// Card component for displaying HealthKit permission errors
/// Provides clear CTAs to grant access or open Settings
struct PermissionErrorCard: View {
    let permissionType: PermissionType
    let onGrantAccess: () -> Void

    @Environment(\.openURL) private var openURL

    enum PermissionType: String {
        case healthKit
        case heartRate
        case hrv

        var icon: String {
            switch self {
            case .healthKit: return "heart.text.square.fill"
            case .heartRate: return "waveform.path.ecg"
            case .hrv: return "heart.circle.fill"
            }
        }

        var title: String {
            switch self {
            case .healthKit: return "Health Access Required"
            case .heartRate: return "Heart Rate Access Needed"
            case .hrv: return "HRV Access Needed"
            }
        }

        var description: String {
            switch self {
            case .healthKit: return "StressMonitor needs access to read your health data for stress calculations. Your data stays private on your device."
            case .heartRate: return "Heart rate data is essential for accurate stress calculation. Grant access to enable monitoring."
            case .hrv: return "Heart Rate Variability is the primary indicator for stress levels. Allow access to continue."
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.error.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: permissionType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.error)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: 8) {
                Text(permissionType.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(permissionType.description)
                    .font(.subheadline)
                    .foregroundColor(.oledTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // CTA buttons
            VStack(spacing: 12) {
                Button(action: onGrantAccess) {
                    Text("Grant Access to Health")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Grant access to Health data")

                Button(action: openSettings) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.caption)
                        Text("Open Settings")
                            .font(.subheadline)
                    }
                    .foregroundColor(.primaryBlue)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Open device Settings")
            }
        }
        .padding(24)
        .background(Color.oledCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(permissionType.title). \(permissionType.description)")
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Preview

#Preview("Permission Error Card") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            PermissionErrorCard(
                permissionType: .healthKit,
                onGrantAccess: {}
            )

            PermissionErrorCard(
                permissionType: .heartRate,
                onGrantAccess: {}
            )
        }
        .padding()
    }
}
