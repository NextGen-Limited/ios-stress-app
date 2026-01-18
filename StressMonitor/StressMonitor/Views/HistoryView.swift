import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: StressViewModel
    @State private var appeared = false

    init(viewModel: StressViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? StressViewModel(
            healthKit: HealthKitManager(),
            algorithm: StressCalculator(),
            repository: StressRepository(modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.historicalData.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("History")
            .refreshable {
                await viewModel.refreshHealthData()
                await viewModel.loadHistoricalData(days: 7)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            if !appeared {
                appeared = true
                await loadInitialData()
            }
        }
    }

    private func loadInitialData() async {
        let repository = StressRepository(modelContext: modelContext)
        let updatedViewModel = StressViewModel(
            healthKit: HealthKitManager(),
            algorithm: StressCalculator(),
            repository: repository
        )
        viewModel = updatedViewModel

        await viewModel.loadHistoricalData(days: 7)
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.historicalData) { measurement in
                HistoryRow(measurement: measurement)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No history available")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Stress measurements will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct HistoryRow: View {
    let measurement: StressMeasurement

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(measurement.category.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.category.rawValue.capitalized)
                    .font(.headline)

                Text(measurement.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(measurement.stressLevel))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(measurement.category.color)

                Text("Stress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
