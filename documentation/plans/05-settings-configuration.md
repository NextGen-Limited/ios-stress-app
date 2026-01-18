# Settings & Configuration

> **Created by:** Phuong Doan
> **Feature:** App settings and user preferences
> **Designs Referenced:** 3 screens
> - `app_settings`
> - `app_configuration_settings_1`, `app_configuration_settings_2`

---

## Overview

The Settings section allows users to:
- Configure measurement reminders
- Set notification thresholds
- Manage display preferences
- Control data & privacy options
- Manage HealthKit access

---

## 1. Settings View

**Design:** `app_settings`, `app_configuration_settings_1`

```swift
// StressMonitor/Views/SettingsView.swift

import SwiftUI
import Observation

@Observable
class AppSettings {
    var userName: String = "John Doe"
    var profileImageURL: String = ""
    var baselineRange: String = "52-68 ms"
    var autoMeasurement: Bool = true
    var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var reminderEnabled: Bool = true
    var stressAlerts: Bool = true
    var alertThreshold: AlertThreshold = .high
    var dailySummary: Bool = false
    var theme: AppTheme = .dark
    var iCloudSync: Bool = true
    var healthAccessStatus: HealthAccessStatus = .authorized

    enum AlertThreshold: Int, CaseIterable, Identifiable {
        case low = 60
        case medium = 75
        case high = 80

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }

        var displayValue: String {
            switch self {
            case .low: return ">60"
            case .medium: return ">75"
            case .high: return ">80"
            }
        }
    }

    enum AppTheme: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    enum HealthAccessStatus {
        case authorized
        case denied
        case notRequested
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings()
    @State private var showProfile = false
    @State private var showHealthAccess = false
    @State private var showDeleteConfirmation = false
    @State private var showReminders = false

    var body: some View {
        List {
            // Profile section
            Section {
                Button(action: { showProfile = true }) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: settings.profileImageURL)) { image in
                            image.resizable()
                        } placeholder: {
                            Circle()
                                .fill(Color.cardDark)
                                .overlay {
                                    Text(String(settings.userName.prefix(1)))
                                        .foregroundColor(.textMain)
                                }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.userName)
                                .font(.system(size: 20, weight: .semibold))

                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                Text("Baseline: \(settings.baselineRange)")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Measurements section
            Section("Measurements") {
                SettingsToggleRow(
                    icon: "watch.face",
                    iconColor: .blue,
                    title: "Auto-Measurement",
                    isOn: $settings.autoMeasurement
                )

                Button(action: { showReminders = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange)
                            Image(systemName: "alarm")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Reminders")
                            .font(.body)

                        Spacer()

                        if settings.reminderEnabled {
                            Text(settings.reminderTime, style: .time)
                                .foregroundColor(.textSecondary)
                        }

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 20))
                    }
                }
            }

            // Notifications section
            Section("Notifications") {
                SettingsToggleRow(
                    icon: "bell.badge.fill",
                    iconColor: .healthRed,
                    title: "Stress Alerts",
                    isOn: $settings.stressAlerts
                )

                Button(action: { /* Alert threshold */ }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple)
                            Image(systemName: "tuningfork")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Alert Threshold")
                            .font(.body)

                        Spacer()

                        Text(settings.alertThreshold.displayValue)
                            .foregroundColor(.textSecondary)

                        Image(systemName: "chevron.right")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 20))
                    }
                }

                Text("Get notified when your stress levels exceed the configured threshold during resting periods.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .listRowInsets(EdgeInsets(top: 0, leading: 56, bottom: 8, trailing: 16))
            }

            // Display section
            Section("Display") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray)
                            Image(systemName: "moon.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .frame(width: 32, height: 32)

                        Text("Theme")
                            .font(.body)
                    }

                    // Theme picker
                    HStack(spacing: 4) {
                        ForEach(AppTheme.AppTheme.allCases, id: \.self) { theme in
                            Button(action: { settings.theme = theme }) {
                                Text(theme.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(settings.theme == theme ? .white : .textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        settings.theme == theme ? Color(UIColor.systemGray5) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(9)
                }
                .padding(.vertical, 4)
            }

            // Data & Privacy section
            Section("Data & Privacy") {
                Button(action: { showHealthAccess = true }) {
                    SettingsNavigationRow(
                        icon: "heart.text.square.fill",
                        iconColor: .healthRed,
                        title: "Health Data Access",
                        value: settings.healthAccessStatus == .authorized ? "Authorized" : "Denied"
                    )
                }

                SettingsToggleRow(
                    icon: "icloud.fill",
                    iconColor: Color(hex: "#38b7f7"),
                    title: "iCloud Sync",
                    isOn: $settings.iCloudSync
                )

                Button(action: { /* Export */ }) {
                    HStack(spacing: 12) {
                        Spacer().frame(width: 28)
                        Text("Export All Data")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.textSecondary)
                    }
                }

                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Text("Delete All Data")
                            .font(.body)
                            .foregroundColor(.healthRed)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Footer
            Section {
                VStack(spacing: 4) {
                    Text("StressMonitor v2.1.0 (Build 405)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProfile) {
            ProfileSettingsView(settings: $settings)
        }
        .sheet(isPresented: $showHealthAccess) {
            HealthAccessSettingsView()
        }
        .sheet(isPresented: $showReminders) {
            ReminderSettingsView(settings: $settings)
        }
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete data
            }
        } message: {
            Text("This will permanently delete all your measurements and settings. This action cannot be undone.")
        }
    }
}

// MARK: - Reminder Settings View
struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Reminders", isOn: $settings.reminderEnabled)

                    if settings.reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $settings.reminderTime,
                            displayedComponents: .hourAndMinute
                        )

                        Picker("Frequency", selection: .constant(1)) {
                            Text("Daily").tag(1)
                            Text("Every Other Day").tag(2)
                            Text("Weekly").tag(3)
                        }
                    }
                }

                Section {
                    Text("Reminders will help you build a consistent measurement habit for more accurate baseline calibration.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
    }
}
```

---

## 2. Profile Settings View

```swift
// StressMonitor/Views/ProfileSettingsView.swift

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var settings: AppSettings
    @State private var editingName = false
    @State private var tempName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // Profile picture
                Section {
                    HStack {
                        Spacer()
                        AsyncImage(url: URL(string: settings.profileImageURL)) { image in
                            image.resizable()
                        } placeholder: {
                            Circle()
                                .fill(Color.cardDark)
                                .overlay {
                                    Text(String(settings.userName.prefix(1)))
                                        .font(.title2)
                                }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary, lineWidth: 2)
                        )

                        Button(action: { /* Change photo */ }) {
                            Text("Change Photo")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Name
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(settings.userName)
                            .foregroundColor(.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .actionSheet(isPresented: $editingName) {
                        ActionSheet(
                            title: Text("Edit Name"),
                            buttons: [
                                .default(Text("Change")) {
                                    editingName = true
                                    tempName = settings.userName
                                },
                                .cancel()
                            ]
                        )
                    }
                }

                // Baseline info
                Section {
                    HStack {
                        Text("Baseline Range")
                        Spacer()
                        Text(settings.baselineRange)
                            .foregroundColor(.textSecondary)
                    }

                    Text("Your personal baseline is calculated from 7 days of measurements and helps personalize your stress insights.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                // Sign out
                Section {
                    Button(action: { /* Sign out */ }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.healthRed)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Edit Name", isPresented: $editingName) {
                TextField("Name", text: $tempName)
                Button("Cancel", role: .cancel) {
                    tempName = ""
                }
                Button("Save") {
                    settings.userName = tempName
                }
            } message: {
                Text("Enter your new name")
            }
        }
    }
}

#Preview {
    ProfileSettingsView(settings: .constant(AppSettings()))
}
```

---

## 3. Health Access Settings View

```swift
// StressMonitor/Views/HealthAccessSettingsView.swift

import SwiftUI
import HealthKit

struct HealthAccessSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.healthKit) private var healthKit
    @State private var accessStatus: HealthAccessStatus = .authorized

    enum HealthAccessStatus {
        case authorized
        case denied
        case notRequested

        var statusText: String {
            switch self {
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            case .notRequested: return "Not Requested"
            }
        }

        var statusColor: Color {
            switch self {
            case .authorized: return .successGreen
            case .denied: return .healthRed
            case .notRequested: return .warningYellow
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        accessStatusRow

                        Text("StressMonitor requires access to your HealthKit data to read heart rate variability and resting heart rate for stress analysis.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if accessStatus != .authorized {
                        Button(action: requestAuthorization) {
                            Text(accessStatus == .denied ? "Open Settings" : "Grant Access")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .background(Color.primary)
                                .cornerRadius(12)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                Section("Data Types") {
                    DataTypeRow(
                        icon: "waveform.path",
                        title: "Heart Rate Variability",
                        description: "Essential for stress detection"
                    )

                    DataTypeRow(
                        icon: "heart.fill",
                        title: "Resting Heart Rate",
                        description: "Baseline calibration"
                    )

                    DataTypeRow(
                        icon: "bed.double.fill",
                        title: "Sleep Analysis",
                        description: "Recovery tracking"
                    )
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 12))
                            Text("Privacy")
                                .font(.headline)
                        }

                        Text("Your health data is processed locally on your device and is never shared with third parties. All data storage is encrypted.")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await checkAccessStatus()
            }
        }
    }

    private var accessStatusRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accessStatus.statusColor.opacity(0.15))
                Image(systemName: accessStatus == .authorized ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(accessStatus.statusColor)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Health Data Access")
                    .font(.body)
                Text(accessStatus.statusText)
                    .font(.caption)
                    .foregroundColor(accessStatus.statusColor)
            }

            Spacer()
        }
    }

    private func checkAccessStatus() async {
        // Check current authorization status
        let status = await healthKit.authorizationStatus()
        accessStatus = status
    }

    private func requestAuthorization() {
        Task {
            await healthKit.requestAuthorization()
            await checkAccessStatus()
        }
    }
}

struct DataTypeRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.healthRed.opacity(0.1))
                Image(systemName: icon)
                    .foregroundColor(.healthRed)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

#Preview {
    HealthAccessSettingsView()
}
```

---

## 4. Export Data View

```swift
// StressMonitor/Views/ExportDataView.swift

import SwiftUI

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportComplete = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                }
                .frame(width: 80, height: 80)

                // Title
                Text("Export Your Data")
                    .font(.title2)

                // Description
                Text("Export all your stress measurements, HRV data, and settings as a CSV file.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Export button
                Button(action: exportData) {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Export Data")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.primary)
                .cornerRadius(28)
                .disabled(isExporting)
                .padding(.horizontal)

                // Info
                VStack(spacing: 8) {
                    InfoRow(icon: "doc.fill", text: "CSV format compatible with Excel, Numbers, etc.")
                    InfoRow(icon: "lock.shield.fill", text: "All data is encrypted and private")
                }
                .padding(.horizontal)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $exportComplete) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func exportData() {
        isExporting = true

        Task {
            // Generate CSV data
            let csv = generateCSV()

            // Write to temp file
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("stress_monitor_export_\(Date().timeIntervalSince1970).csv")

            try? csv.write(to: fileURL, atomically: true, encoding: .utf8)

            await MainActor.run {
                isExporting = false
                shareURL = fileURL
                exportComplete = true
            }
        }
    }

    private func generateCSV() -> String {
        """
        Date,Stress Level,HRV (ms),Heart Rate (bpm),Category
        """
        // Add actual data
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.textSecondary)
                .frame(width: 24)
            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    ExportDataView()
}
```

---

## File Structure

```
StressMonitor/Views/Settings/
├── SettingsView.swift
├── ProfileSettingsView.swift
├── HealthAccessSettingsView.swift
├── ReminderSettingsView.swift
├── ExportDataView.swift
└── Components/
    ├── SettingsToggleRow.swift
    └── SettingsNavigationRow.swift
```

---

## Dependencies

- **Design System:** Components, colors from `00-design-system-components.md`
- **HealthKit:** For checking authorization status
- **ShareSheet:** For data export functionality
