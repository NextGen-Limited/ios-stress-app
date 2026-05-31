import SwiftUI
import Charts

/// Main dashboard with Welltory-inspired real-time stress monitoring.
/// Features a circular stress gauge, HRV trend chart, and recent readings list.
struct DashboardView: View {
    @EnvironmentObject var healthManager: HealthKitManager

    @State private var showingPermissionAlert = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Connection status
                    if !healthManager.isAuthorized {
                        authorizationBanner
                    }

                    if !healthManager.isMonitoring && healthManager.isAuthorized {
                        startMonitoringBanner
                    }

                    // Main stress gauge (Welltory-style)
                    StressScoreView(
                        score: healthManager.currentStressLevel,
                        category: healthManager.predictor.currentCategory,
                        coherence: healthManager.predictor.coherence,
                        hrv: healthManager.lastHRV,
                        heartRate: healthManager.lastHeartRate,
                        trend: healthManager.predictor.trendSlope
                    )

                    // Live indicator
                    if healthManager.isMonitoring {
                        liveIndicator
                    }

                    // HRV Trend Chart
                    HRVTrendChartView(
                        hrvData: healthManager.hrvHistory,
                        stressScores: healthManager.predictor.recentScores
                    )

                    // Stress Score Trend
                    StressScoreChartView(
                        scores: healthManager.predictor.recentScores
                    )

                    // Recent Readings
                    RecentReadingsView(readings: healthManager.recentReadings)
                }
                .padding()
            }
            .navigationTitle("Stress Monitor")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(isRefreshing)
                }
            }
            .alert("HealthKit Access Required", isPresented: $showingPermissionAlert) {
                #if os(iOS)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                #endif
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("StressMonitor needs access to your health data to monitor stress levels. Please grant permission in Settings.")
            }
            .task {
                await initialLoad()
            }
        }
    }

    // MARK: - Subviews

    private var authorizationBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.slash")
                .font(.title2)
                .foregroundColor(.red)

            Text("Health Data Access Required")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Grant access to Heart Rate and HRV data to start monitoring.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Grant Access") {
                Task {
                    do {
                        try await healthManager.requestAuthorization()
                    } catch {
                        showingPermissionAlert = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var startMonitoringBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.circle")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Ready to Monitor")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Start real-time stress monitoring with your Apple Watch.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Start Monitoring") {
                healthManager.startMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var liveIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .shadow(color: .green.opacity(0.5), radius: 4)

            Text("Live")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            if let lastUpdate = healthManager.lastUpdate {
                Text("•")
                    .foregroundColor(.secondary)
                Text(lastUpdate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func initialLoad() async {
        if healthManager.isAuthorized {
            healthManager.startMonitoring()
        }
    }

    private func refresh() {
        isRefreshing = true
        Task {
            healthManager.startMonitoring()
            try? await Task.sleep(for: .seconds(1))
            isRefreshing = false
        }
    }
}

// MARK: - Recent Readings (Enhanced)

struct RecentReadingsView: View {
    let readings: [StressReading]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Readings")
                    .font(.headline)

                Spacer()

                if !readings.isEmpty {
                    Text("\(readings.count) readings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if readings.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No readings yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Start monitoring to see stress readings")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(readings.prefix(10)) { reading in
                    ReadingRow(reading: reading)

                    if reading.id != readings.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Reading Row

struct ReadingRow: View {
    let reading: StressReading

    var body: some View {
        HStack(spacing: 12) {
            // Stress indicator
            Circle()
                .fill(stressColor)
                .frame(width: 10, height: 10)

            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.timestamp, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(reading.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Metrics
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f ms", reading.hrv))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Text("HRV")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f bpm", reading.heartRate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    Text("HR")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Stress level
            Text(String(format: "%.0f%%", reading.level * 100))
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(stressColor)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    private var stressColor: Color {
        switch reading.level {
        case 0..<0.2:  return .green
        case 0.2..<0.4: return .blue
        case 0.4..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default:         return .red
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(HealthKitManager())
}
