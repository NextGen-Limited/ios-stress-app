import SwiftUI

/// Full settings view with user preferences, baseline configuration,
/// HealthKit status, data management, and app info.
struct SettingsView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var cloudKitManager: CloudKitManager

    // MARK: - Persisted Settings (@AppStorage)

    @AppStorage(UserSettings.notificationsEnabledKey) private var notificationsEnabled = true
    @AppStorage(UserSettings.alertThresholdKey) private var alertThreshold = UserSettings.defaultAlertThreshold
    @AppStorage(UserSettings.dailySummaryEnabledKey) private var dailySummaryEnabled = false

    @AppStorage(UserSettings.useManualBaselineKey) private var useManualBaseline = false
    @AppStorage(UserSettings.manualBaselineHRVKey) private var manualBaselineHRV = UserSettings.defaultManualBaselineHRV
    @AppStorage(UserSettings.manualBaselineHeartRateKey) private var manualBaselineHR = UserSettings.defaultManualBaselineHeartRate
    @AppStorage(UserSettings.highStressThresholdKey) private var highStressThreshold = UserSettings.defaultHighStressThreshold

    @AppStorage(UserSettings.displayStyleKey) private var displayStyle = StressDisplayStyle.gauge.rawValue
    @AppStorage(UserSettings.historyDaysKey) private var historyDays = UserSettings.defaultHistoryDays
    @AppStorage(UserSettings.showHRVRawKey) private var showHRVRaw = false

    @AppStorage(UserSettings.cloudSyncEnabledKey) private var cloudSyncEnabled = true
    @AppStorage(UserSettings.autoExportKey) private var autoExportFrequency = AutoExportFrequency.off.rawValue

    // MARK: - Local State

    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var baselineApplied = false

    var body: some View {
        NavigationStack {
            Form {
                // HealthKit Status
                healthKitSection

                // Notifications
                notificationSection

                // Baseline Configuration
                baselineSection

                // Stress Thresholds
                thresholdSection

                // Display Preferences
                displaySection

                // Data Management
                dataSection

                // About
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - HealthKit Status

    private var healthKitSection: some View {
        Section {
            HStack {
                Label("HealthKit Access", systemImage: "heart.text.square")
                Spacer()
                if healthManager.isAuthorized {
                    Text("Authorized")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Not Authorized")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }

            HStack {
                Label("Monitoring", systemImage: "waveform.path.ecg")
                Spacer()
                if healthManager.isMonitoring {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Inactive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if !healthManager.isAuthorized {
                Button {
                    Task {
                        do {
                            try await healthManager.requestAuthorization()
                        } catch {
                            // Error handled by the HealthKitManager state
                        }
                    }
                } label: {
                    Label("Grant HealthKit Access", systemImage: "lock.open")
                }
            }
        } header: {
            Text("Health Data")
        } footer: {
            Text("StressMonitor reads Heart Rate and HRV data from Apple Watch via HealthKit.")
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label("Stress Alerts", systemImage: "bell.badge")
            }

            if notificationsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Alert Threshold")
                        Spacer()
                        Text("\(Int(alertThreshold * 100))%")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $alertThreshold, in: 0.3...0.95, step: 0.05)
                        .tint(stressColor(for: alertThreshold))
                }

                Toggle(isOn: $dailySummaryEnabled) {
                    Label("Daily Summary", systemImage: "chart.bar.doc.horizontal")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notificationsEnabled {
                Text("You'll be alerted when stress exceeds \(Int(alertThreshold * 100))%.")
            }
        }
    }

    // MARK: - Baseline Configuration

    private var baselineSection: some View {
        Section {
            Toggle(isOn: $useManualBaseline) {
                Label("Manual Baseline", systemImage: "slider.horizontal.3")
            }

            if useManualBaseline {
                VStack(alignment: .leading, spacing: 12) {
                    // Baseline HRV
                    HStack {
                        Text("Baseline HRV")
                        Spacer()
                        Text(String(format: "%.0f ms", manualBaselineHRV))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $manualBaselineHRV, in: 20...150, step: 1)
                        .tint(.blue)

                    // Baseline Heart Rate
                    HStack {
                        Text("Baseline HR")
                        Spacer()
                        Text(String(format: "%.0f bpm", manualBaselineHR))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $manualBaselineHR, in: 40...100, step: 1)
                        .tint(.red)
                }

                Button {
                    applyManualBaseline()
                } label: {
                    HStack {
                        Label("Apply Baseline", systemImage: "checkmark.circle")
                        if baselineApplied {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .disabled(baselineApplied)
            } else {
                // Show auto-computed baselines (read-only)
                HStack {
                    Text("Auto HRV Baseline")
                    Spacer()
                    Text(String(format: "%.0f ms", healthManager.predictor.baselineHRV))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text("Auto HR Baseline")
                    Spacer()
                    Text(String(format: "%.0f bpm", healthManager.predictor.baselineHeartRate))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Baseline Configuration")
        } footer: {
            Text("Baselines personalize stress scoring to your body. Auto baselines are computed from your 7-day average.")
        }
    }

    // MARK: - Stress Thresholds

    private var thresholdSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("High Stress Threshold")
                    Spacer()
                    Text("\(Int(highStressThreshold * 100))%")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $highStressThreshold, in: 0.3...0.9, step: 0.05)
                    .tint(.orange)
            }

            // Category legend
            VStack(alignment: .leading, spacing: 6) {
                Text("Stress Categories")
                    .font(.subheadline)
                    .fontWeight(.medium)

                CategoryRow(label: "Resting", range: "0–20%", color: .green)
                CategoryRow(label: "Low", range: "20–40%", color: .blue)
                CategoryRow(label: "Moderate", range: "40–\(Int(highStressThreshold * 100))%", color: .yellow)
                CategoryRow(label: "High", range: "\(Int(highStressThreshold * 100))–80%", color: .orange)
                CategoryRow(label: "Very High", range: "80–100%", color: .red)
            }
            .font(.caption)
        } header: {
            Text("Stress Thresholds")
        } footer: {
            Text("Adjust the high stress boundary. This affects when alerts trigger and how categories are labeled.")
        }
    }

    // MARK: - Display Preferences

    private var displaySection: some View {
        Section {
            Picker("Display Style", selection: $displayStyle) {
                ForEach(StressDisplayStyle.allCases) { style in
                    Text(style.displayName).tag(style.rawValue)
                }
            }

            Stepper("History: \(historyDays) days", value: $historyDays, in: 1...30, step: 1)

            Toggle(isOn: $showHRVRaw) {
                Label("Show HRV Values", systemImage: "number")
            }
        } header: {
            Text("Display")
        } footer: {
            Text("Control how stress data is visualized on the dashboard.")
        }
    }

    // MARK: - Data Management

    private var dataSection: some View {
        Section {
            Toggle(isOn: $cloudSyncEnabled) {
                Label("CloudKit Sync", systemImage: "icloud")
            }

            Picker("Auto Export", selection: $autoExportFrequency) {
                ForEach(AutoExportFrequency.allCases) { freq in
                    Text(freq.displayName).tag(freq.rawValue)
                }
            }

            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("CloudKit syncs stress data across your devices via iCloud.")
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                resetSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all preferences to their defaults. Your stress data will not be affected.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(appBuild)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            HStack {
                Text("Platform")
                Spacer()
                Text("iOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://github.com/stress-monitor")!) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Actions

    private func applyManualBaseline() {
        healthManager.predictor.updateBaselines(
            averageHRV: manualBaselineHRV,
            averageHeartRate: manualBaselineHR
        )
        withAnimation {
            baselineApplied = true
        }
        // Reset indicator after brief feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                baselineApplied = false
            }
        }
    }

    private func resetSettings() {
        notificationsEnabled = true
        alertThreshold = UserSettings.defaultAlertThreshold
        dailySummaryEnabled = false
        useManualBaseline = false
        manualBaselineHRV = UserSettings.defaultManualBaselineHRV
        manualBaselineHR = UserSettings.defaultManualBaselineHeartRate
        highStressThreshold = UserSettings.defaultHighStressThreshold
        displayStyle = StressDisplayStyle.gauge.rawValue
        historyDays = UserSettings.defaultHistoryDays
        showHRVRaw = false
        cloudSyncEnabled = true
        autoExportFrequency = AutoExportFrequency.off.rawValue
    }

    // MARK: - Helpers

    private func stressColor(for value: Double) -> Color {
        switch value {
        case 0..<0.2:   return .green
        case 0.2..<0.4: return .blue
        case 0.4..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default:         return .red
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let label: String
    let range: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .frame(width: 80, alignment: .leading)
            Text(range)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(HealthKitManager())
        .environmentObject(CloudKitManager())
}
