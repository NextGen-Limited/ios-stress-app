import SwiftUI
import SwiftData

struct DashboardView: View {
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
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if let stress = viewModel.currentStress {
                        stressRing(stress)
                        detailsCard(stress)
                    } else {
                        emptyState
                    }

                    if let heartRate = viewModel.liveHeartRate {
                        heartRateCard(heartRate)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
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

        await viewModel.loadCurrentStress()
        await viewModel.loadBaseline()
        viewModel.observeHeartRate()
    }

    private func stressRing(_ stress: StressResult) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(stress.category.color.opacity(0.2), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: stress.level / 100)
                    .stroke(stress.category.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: stress.level)

                VStack {
                    Image(systemName: stress.category.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(stress.category.color)

                    Text("\(Int(stress.level))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(stress.category.color)

                    Text(stress.category.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
        }
    }

    private func detailsCard(_ stress: StressResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            DetailRow(label: "HRV", value: "\(Int(stress.hrv)) ms")
            DetailRow(label: "Heart Rate", value: "\(Int(stress.heartRate)) bpm")
            DetailRow(label: "Confidence", value: "\(Int(stress.confidence * 100))%")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func heartRateCard(_ heartRate: Double) -> some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)

            VStack(alignment: .leading) {
                Text("Live Heart Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(Int(heartRate)) bpm")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No stress data available")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Refresh") {
                Task {
                    await viewModel.refreshHealthData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    DashboardView()
}
