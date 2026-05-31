import SwiftUI
import HealthKit

/// Card component for HealthKit permission denied/required state.
/// Provides CTAs to grant access (system prompt) or open Settings (deep link).
struct PermissionCardView: View {
    let permissionType: PermissionType
    var isLoading: Bool = false
    var embedded: Bool = false
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
            case .healthKit:
                return "StressMonitor needs access to read your health data for stress calculations. Your data stays private on your device."
            case .heartRate:
                return "Heart rate data is essential for accurate stress calculation. Grant access to enable monitoring."
            case .hrv:
                return "Heart Rate Variability is the primary indicator for stress levels. Allow access to continue."
            }
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon with rounded-square container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.error.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: permissionType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.error)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: Spacing.sm) {
                Text(permissionType.title)
                    .font(Typography.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(permissionType.description)
                    .font(Typography.subheadline)
                    .foregroundColor(.oledTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // CTA buttons
            VStack(spacing: Spacing.md) {
                Button(action: onGrantAccess) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Grant Access to Health")
                    }
                    .font(Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isLoading ? Color.gray : Color.primaryGreen)
                    .cornerRadius(26)
                }
                .disabled(isLoading)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Grant access to Health data")

                SecondaryButton(title: "Open Settings", action: openSettings)
                    .accessibilityLabel("Open device Settings")
            }
        }
        .padding(Spacing.cardPadding)
        .background(embedded ? Color.clear : Color.oledCardBackground)
        .cornerRadius(embedded ? 0 : Spacing.settingsCardRadius)
        .shadow(embedded ? ShadowDefinition(color: .clear, radius: 0, x: 0, y: 0) : AppShadow.elevated)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Preview

#Preview("Permission Card - Default") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            PermissionCardView(
                permissionType: .healthKit,
                onGrantAccess: {}
            )

            PermissionCardView(
                permissionType: .heartRate,
                onGrantAccess: {}
            )
        }
        .padding()
    }
}

#Preview("Permission Card - Loading") {
    ZStack {
        Color.oledBackground.ignoresSafeArea()

        PermissionCardView(
            permissionType: .healthKit,
            isLoading: true,
            onGrantAccess: {}
        )
        .padding()
    }
}
