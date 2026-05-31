import SwiftUI

/// Health data sync card showing data types and HRV accuracy tips
struct HealthDataCard: View {
    let onSyncNow: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(
                    icon: "heart.text.square.fill",
                    title: "Health Data"
                )

                // Sync now button
                syncButton

                // Data types list
                dataTypesList

                // HRV accuracy tip banner
                HRVAccuracyBanner()
            }
        }
    }

    // MARK: - Subviews

    private var syncButton: some View {
        Button(action: onSyncNow) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text("Sync now")
                    .font(.system(size: 14.9, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 35.5)
            .background(Color.accentTeal)
            .clipShape(Capsule())
        }
        .accessibilityLabel("Sync health data now")
    }

    private var dataTypesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Types")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)

            ForEach(HealthDataType.allCases, id: \.self) { type in
                Text(type.displayName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - HRV Accuracy Banner

/// Yellow info banner with steps to improve HRV accuracy via AFib history
struct HRVAccuracyBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Improve HRV Accuracy")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    Text("1. Turning on the AFib (Atrial Fibrillation) history feature in the Apple Health app under Heart.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)

                    Text("2. Enabling AFib History in the Watch app under Heart section.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)

                        Text("• This feature is currently the only way to increase the HRV monitoring frequency of the Apple Watch and will use more battery.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.primary)

                        Text("• Not available in mainland China.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(Color.bannerYellow)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.settingsCardShadowColor.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Data Type Model

/// Supported health data types displayed in settings
enum HealthDataType: CaseIterable {
    case hrv, restingHeartRate, heartbeats, sleepAnalysis, workoutData

    var displayName: String {
        switch self {
        case .hrv: return "Heart Rate Variability (HRV)"
        case .restingHeartRate: return "Resting Heart Rate (RHR)"
        case .heartbeats: return "Heartbeats (RR)"
        case .sleepAnalysis: return "Sleep Analysis"
        case .workoutData: return "Workout Data"
        }
    }
}

#Preview {
    ScrollView {
        HealthDataCard(onSyncNow: {})
            .padding()
    }
    .background(Color.adaptiveSettingsBackground)
}
