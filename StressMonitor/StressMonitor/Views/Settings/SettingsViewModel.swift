import SwiftUI
import SwiftData

@Observable
class SettingsViewModel {
    var userProfile: UserProfile
    var notificationSettings: NotificationSettings
    var exportSettings: ExportSettings
    var isDeletingAllData = false

    private let repository: StressRepositoryProtocol

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
        self.userProfile = UserProfile(name: "", age: nil, restingHeartRate: 60, baselineHRV: 50)
        self.notificationSettings = NotificationSettings()
        self.exportSettings = ExportSettings()
    }

    func loadUserProfile() async {
        if let baseline = try? await repository.getBaseline() {
            userProfile = UserProfile(
                name: "",
                age: nil,
                restingHeartRate: baseline.restingHeartRate,
                baselineHRV: baseline.baselineHRV
            )
        }
    }

    func updateProfile(_ profile: UserProfile) async throws {
        let baseline = PersonalBaseline(
            restingHeartRate: profile.restingHeartRate,
            baselineHRV: profile.baselineHRV,
            lastUpdated: Date()
        )
        try await repository.updateBaseline(baseline)
        userProfile = profile
    }

    func deleteAllMeasurements() async throws {
        isDeletingAllData = true
        defer { isDeletingAllData = false }
        try await repository.deleteAllMeasurements()
    }
}

struct UserProfile: Codable {
    var name: String
    var age: Int?
    var restingHeartRate: Double
    var baselineHRV: Double
}

struct NotificationSettings: Codable {
    var highStressAlerts: Bool = true
    var dailyReminders: Bool = true
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var weeklyReport: Bool = true
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
}

enum ExportFormat: String, CaseIterable, Codable {
    case csv = "CSV"
    case json = "JSON"
}
