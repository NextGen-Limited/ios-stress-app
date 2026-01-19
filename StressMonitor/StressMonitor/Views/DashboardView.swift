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
            Group {
                if viewModel.isLoading && viewModel.currentStress == nil {
                    loadingView
                } else if let stress = viewModel.currentStress {
                    content(stress)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Now")
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
        viewModel = StressViewModel(
            healthKit: HealthKitManager(),
            algorithm: StressCalculator(),
            repository: repository
        )

        await viewModel.loadCurrentStress()
        await viewModel.loadBaseline()
        viewModel.observeHeartRate()
    }

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading stress data...")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func content(_ stress: StressResult) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Layout.sectionSpacing) {
                header

                StressRingView(stressLevel: stress.level, category: stress.category)
                    .frame(height: 280)

                statusText(stress)

                MeasureButton(isLoading: viewModel.isLoading) {
                    await measureStress(stress.category)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)

                if viewModel.liveHeartRate != nil {
                    liveHeartRateCard
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(greeting)
                .font(.system(size: DesignTokens.Typography.title, weight: .bold))

            Text("Here's your current stress level")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func statusText(_ stress: StressResult) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: stress.category.icon)
                .font(.system(size: 20))

            Text(stress.category.rawValue.capitalized)
                .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))

            Text("•")
                .foregroundColor(.secondary)

            Text("\(Int(stress.confidence * 100))% confidence")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.secondary)
        }
    }

    private var liveHeartRateCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Live Heart Rate")
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(.secondary)

                Text("\(Int(viewModel.liveHeartRate ?? 0)) bpm")
                    .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
            }

            Spacer()
        }
        .padding(DesignTokens.Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No stress data available")
                .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Tap below to measure your current stress level")
                .font(.system(size: DesignTokens.Typography.body))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            MeasureButton {
                await measureStress(nil)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private func measureStress(_ previousCategory: StressCategory?) async {
        do {
            try await viewModel.calculateAndSaveStress()

            if let newCategory = viewModel.currentStress?.category, newCategory != previousCategory {
                HapticManager.shared.stressLevelChanged(to: newCategory)
            }
        } catch {
            // Error handled by viewModel.errorMessage
        }
    }
}

#Preview {
    DashboardView()
}
