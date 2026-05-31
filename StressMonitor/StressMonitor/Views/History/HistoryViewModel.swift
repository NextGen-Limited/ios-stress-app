import SwiftUI
import SwiftData

@Observable
class HistoryViewModel {
    var measurements: [StressMeasurement] = []
    var selectedTimeRange: TimeRange = .sevenDays
    var isLoading = false
    var errorMessage: String?

    private let repository: StressRepositoryProtocol

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.repository = StressRepository(modelContext: modelContext, baselineCalculator: baselineCalculator)
    }

    func fetchMeasurements() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let calendar = Calendar.current
            let now = Date()
            var startDate: Date

            switch selectedTimeRange {
            case .twentyFourHours:
                startDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
            case .sevenDays:
                startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .fourWeeks:
                startDate = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
            case .threeMonths:
                startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            }

            measurements = try await repository.fetchMeasurements(from: startDate, to: now)
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

    var groupedMeasurements: [String: [StressMeasurement]] {
        Dictionary(grouping: measurements) { measurement in
            formatDateGroup(measurement.timestamp)
        }
    }

    private func formatDateGroup(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            let daysSince = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if daysSince <= 7 {
                return "PREVIOUS 7 DAYS"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, YYYY"
                return formatter.string(from: date).uppercased()
            }
        }
    }
}

enum TimeRange: String, CaseIterable {
    case twentyFourHours = "24H"
    case sevenDays = "7D"
    case fourWeeks = "4W"
    case threeMonths = "3M"
}
