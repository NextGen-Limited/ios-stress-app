import SwiftUI
import SwiftData

@Observable
class SettingsViewModel {
    var userProfile: UserProfile
    var notificationSettings: NotificationSettings
    var exportSettings: ExportSettings
    var isDeletingAllData = false
    var latestStressLevel: Double = 35
    var bioAge: Int? = nil
    var streakDays: Int = 0

    private let repository: StressRepositoryProtocol
    private let bioAgeCalculator = BioAgeCalculator()

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
        self.userProfile = UserProfile(name: UserDefaults.standard.string(forKey: "profile.name") ?? "",
                                        age: nil,
                                        restingHeartRate: 60,
                                        baselineHRV: 50)
        self.notificationSettings = NotificationSettings.load()
        self.exportSettings = ExportSettings()
    }

    func loadUserProfile() async {
        if let baseline = try? await repository.getBaseline() {
            userProfile = UserProfile(
                name: userProfile.name,
                age: userProfile.age,
                restingHeartRate: baseline.restingHeartRate,
                baselineHRV: baseline.baselineHRV
            )
        }

        let recent = (try? await repository.fetchRecent(limit: 30)) ?? []
        if let latestMeasurement = recent.first {
            latestStressLevel = latestMeasurement.stressLevel
        }

        streakDays = Self.computeStreak(from: recent)
        bioAge = computeBioAge(recent: recent)

        notificationSettings.persist()
    }

    var displayName: String {
        let raw = userProfile.name.trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? "You" : raw
    }

    var displayEmail: String? {
        let raw = userProfile.name.trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? nil : UserDefaults.standard.string(forKey: "profile.email")
    }

    func updateProfile(_ profile: UserProfile) async throws {
        let baseline = PersonalBaseline(
            restingHeartRate: profile.restingHeartRate,
            baselineHRV: profile.baselineHRV,
            lastUpdated: Date()
        )
        try await repository.updateBaseline(baseline)
        userProfile = profile
        UserDefaults.standard.set(profile.name, forKey: "profile.name")
    }

    func deleteAllMeasurements() async throws {
        isDeletingAllData = true
        defer { isDeletingAllData = false }
        try await repository.deleteAllMeasurements()
    }

    private func computeBioAge(recent: [StressMeasurement]) -> Int? {
        let chronological = userProfile.age ?? 35
        let avgHRV = recent.isEmpty ? nil : recent.map(\.hrv).reduce(0, +) / Double(recent.count)
        let rhr = userProfile.restingHeartRate > 0 ? userProfile.restingHeartRate : nil
        guard let result = bioAgeCalculator.calculate(
            chronologicalAge: chronological,
            hrv: avgHRV,
            restingHeartRate: rhr,
            sleepEfficiency: nil
        ) else { return nil }
        return result.estimatedAge
    }

    private static func computeStreak(from measurements: [StressMeasurement]) -> Int {
        guard !measurements.isEmpty else { return 0 }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: measurements) { calendar.startOfDay(for: $0.timestamp) }
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while grouped[cursor] != nil {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }
}

struct UserProfile: Codable {
    var name: String
    var age: Int?
    var restingHeartRate: Double
    var baselineHRV: Double
}

struct NotificationSettings: Codable {
    var stressAlertsEnabled: Bool = true
    var waterReminderEnabled: Bool = true
    var dailySummaryEnabled: Bool = false

    private static let storageKey = "settings.notifications"

    static func load() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationSettings()
        }
        return decoded
    }

    func persist() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

struct ExportSettings: Codable {
    var includeHRV: Bool = true
    var includeHeartRate: Bool = true
    var includeStressLevel: Bool = true
    var dateRange: ExportDateRange = .week
    var format: ExportFormat = .csv
}

enum ExportDateRange: String, CaseIterable, Codable {
    case day = "Last 24 Hours"
    case week = "Last 7 Days"
    case month = "Last 4 Weeks"
    case threeMonths = "Last 3 Months"
    case all = "All Time"
    case custom = "Custom"
}

enum ExportFormat: String, CaseIterable, Codable {
    case csv = "CSV"
    case json = "JSON"
}
