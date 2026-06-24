import SwiftUI
import SwiftData

@Observable
class HistoryViewModel {
    var measurements: [StressMeasurement] = []
    var dateRange: DateRangeFilter = .sevenDays
    var selectedCategories: Set<StressCategory> = []
    var isLoading = false
    var errorMessage: String?

    private let repository: StressRepositoryProtocol

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
    }

    /// Combined filter state for external consumers.
    var filter: HistoryFilter {
        HistoryFilter(dateRange: dateRange, categories: selectedCategories)
    }

    func updateFilter(_ filter: HistoryFilter) {
        dateRange = filter.dateRange
        selectedCategories = filter.categories
        Task { await fetchMeasurements() }
    }

    func fetchMeasurements() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let calendar = Calendar.current
            let now = Date()
            let startDate: Date

            if let cutoff = dateRange.cutoff(from: now) {
                startDate = cutoff
            } else {
                startDate = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            }

            let raw = try await repository.fetchMeasurements(from: startDate, to: now)
            measurements = applyCategoryFilter(raw)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMeasurement(_ measurement: StressMeasurement) async {
        do {
            try await repository.delete(measurement)
            measurements.removeAll { $0.id == measurement.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyCategoryFilter(_ items: [StressMeasurement]) -> [StressMeasurement] {
        guard !selectedCategories.isEmpty else { return items }
        return items.filter { selectedCategories.contains($0.category) }
    }

    // MARK: - Grouping (by day)

    struct DayGroup: Identifiable {
        let id: String
        let title: String
        let count: Int
        let measurements: [StressMeasurement]
    }

    var dayGroups: [DayGroup] {
        let grouped = Dictionary(grouping: measurements) { dayKey($0.timestamp) }
        return grouped
            .map { (key, items) in
                DayGroup(
                    id: key,
                    title: dayTitle(key, items: items),
                    count: items.count,
                    measurements: items.sorted { $0.timestamp > $1.timestamp }
                )
            }
            .sorted { $0.id > $1.id }
    }

    // MARK: - Summary tiles

    var averageScore7d: Double? {
        let now = Date()
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) else { return nil }
        let recent = measurements.filter { $0.timestamp >= cutoff }
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0) { $0 + $1.stressLevel } / Double(recent.count)
    }

    var bestScore: (value: Double, label: String)? {
        guard let best = measurements.min(by: { $0.stressLevel < $1.stressLevel }) else { return nil }
        return (best.stressLevel, shortDayLabel(best.timestamp))
    }

    var peakScore: (value: Double, label: String)? {
        guard let peak = measurements.max(by: { $0.stressLevel < $1.stressLevel }) else { return nil }
        return (peak.stressLevel, shortDayLabel(peak.timestamp))
    }

    // MARK: - Date helpers

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dayTitle(_ key: String, items: [StressMeasurement]) -> String {
        let cal = Calendar.current
        guard let date = items.first?.timestamp else { return key }
        if cal.isDateInToday(date) {
            return "Today · \(formatDayDate(date))"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday · \(formatDayDate(date))"
        }
        return formatDayDate(date)
    }

    private func formatDayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: date)
    }

    private func shortDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - HistoryFilter

/// Combined filter state for history views.
struct HistoryFilter: Hashable {
    var dateRange: DateRangeFilter
    var categories: Set<StressCategory>

    static let defaultAll = HistoryFilter(dateRange: .all, categories: [])
}

// MARK: - TimeRange (legacy, kept for compatibility)

enum TimeRange: String, CaseIterable {
    case twentyFourHours = "24H"
    case sevenDays = "7D"
    case fourWeeks = "4W"
    case threeMonths = "3M"
}
