import SwiftUI
import SwiftData

/// ViewModel for TrendView
/// Manages data fetching and state for the trend dashboard
@Observable
class TrendViewModel {
    // MARK: - Published Properties

    var measurements: [StressMeasurement] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {
        fetchData()
    }

    // MARK: - Public Methods

    func fetchData() {
        isLoading = true
        errorMessage = nil

        Task {
            await fetchMeasurements()
            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Private Methods

    private func fetchMeasurements() async {
        // Fetch last 7 days of measurements
        guard let context = modelContext else {
            errorMessage = "Database not available"
            return
        }

        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate { $0.timestamp >= weekAgo },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            measurements = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load measurements"
            measurements = []
        }
    }
}
