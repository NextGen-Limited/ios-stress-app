import SwiftUI
import HealthKit

/// Health data sync card showing data types, permission status, and HRV accuracy tips.
struct HealthDataCard: View {
    let onSyncNow: () -> Void
    @State private var healthAuthStatus: HKAuthorizationStatus = .notDetermined
    @State private var isRequestingPermission = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(
                    icon: "heart.text.square.fill",
                    title: "Health Data",
                    color: .primaryGreen
                )

                // Permission status row
                permissionStatusRow

                // Sync now button (only if authorized)
                if healthAuthStatus == .sharingAuthorized {
                    syncButton
                }

                // Data types list
                dataTypesList

                // HRV accuracy tip banner
                HRVAccuracyBanner()
            }
        }
        .onAppear { refreshAuthStatus() }
        .alert("Health Access Needed", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Ripple needs Health access to read your stress data. Please enable it in Settings → Privacy → Health.")
        }
    }

    // MARK: - Permission Status

    private var permissionStatusRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Health Access")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)
                Text(statusText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if healthAuthStatus != .sharingAuthorized {
                Button(action: requestPermission) {
                    HStack(spacing: 4) {
                        if isRequestingPermission {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 12))
                        }
                        Text("Enable")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.accentTeal)
                }
                .disabled(isRequestingPermission)
                .accessibilityLabel("Request Health access")
            }
        }
    }

    private var statusColor: Color {
        switch healthAuthStatus {
        case .sharingAuthorized: return .green
        case .sharingDenied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }

    private var statusText: String {
        switch healthAuthStatus {
        case .sharingAuthorized: return "Access granted"
        case .sharingDenied: return "Access denied — tap to enable"
        case .notDetermined: return "Not requested yet"
        @unknown default: return "Unknown"
        }
    }

    private func refreshAuthStatus() {
        healthAuthStatus = HKHealthStore().authorizationStatus(for: .quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
    }

    private func requestPermission() {
        isRequestingPermission = true
        guard HKHealthStore.isHealthDataAvailable() else {
            isRequestingPermission = false
            return
        }

        let store = HKHealthStore()
        let types: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKCategoryType(.sleepAnalysis),
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]

        store.requestAuthorization(toShare: [], read: types) { _, _ in
            Task { @MainActor in
                isRequestingPermission = false
                refreshAuthStatus()
                if healthAuthStatus == .sharingDenied {
                    showPermissionDeniedAlert = true
                }
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
            .background(Color.settingsRippleBlue)
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

                    Text("2. Enabling AFib History in the Watch app settings.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color.settingsAmberInfo)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

struct HealthDataCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            HealthDataCard(onSyncNow: {})
                .padding()
        }
        .background(Color.adaptiveSettingsBackground)
    }
}
