import SwiftUI

struct SettingsView: View {
    @AppStorage("baselineHRV") private var baselineHRV: Double = 50
    @AppStorage("restingHeartRate") private var restingHeartRate: Double = 60
    @AppStorage("autoMeasureEnabled") private var autoMeasureEnabled: Bool = true

    var body: some View {
        Form {
            baselineSection
            measurementSection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .accessibilityIdentifier("SettingsView")
    }

    private var baselineSection: some View {
        Section("Health Baseline") {
            HStack {
                Text("Baseline HRV")
                    .accessibilityLabel("Baseline Heart Rate Variability")
                Spacer()
                Text("\(String(format: "%.0f", baselineHRV)) ms")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue("\(String(format: "%.0f", baselineHRV)) milliseconds")

            HStack {
                Text("Resting Heart Rate")
                Spacer()
                Text("\(String(format: "%.0f", restingHeartRate)) bpm")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue("\(String(format: "%.0f", restingHeartRate)) beats per minute")
        }
    }

    private var measurementSection: some View {
        Section("Measurement") {
            Toggle("Auto-measure", isOn: $autoMeasureEnabled)
                .accessibilityHint("Automatically measure stress levels throughout the day")

            if autoMeasureEnabled {
                HStack {
                    Text("Frequency")
                    Spacer()
                    Text("Every hour")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                // Export functionality placeholder
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                    Text("Export History")
                }
            }
            .accessibilityIdentifier("Export History Button")

            Button(role: .destructive) {
                resetBaseline()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Baseline")
                }
            }
            .accessibilityIdentifier("Reset Baseline Button")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func resetBaseline() {
        baselineHRV = 50
        restingHeartRate = 60
        HapticManager.shared.success()
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
