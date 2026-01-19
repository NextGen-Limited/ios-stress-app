import SwiftUI
import SwiftData

struct StressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showingBreathing = false

    var body: some View {
        ZStack {
            Color.backgroundLight
                .ignoresSafeArea()

            Group {
                if let viewModel = viewModel {
                    contentView(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
        }
        .task {
            await setupViewModel()
        }
        .sheet(isPresented: $showingBreathing) {
            breathingPlaceholder
        }
    }

    private func setupViewModel() async {
        let repository = StressRepository(modelContext: modelContext)
        let healthKit = HealthKitManager()
        let algorithm = StressCalculator()

        viewModel = DashboardViewModel(
            healthKit: healthKit,
            algorithm: algorithm,
            repository: repository
        )

        await viewModel?.refreshStressLevel()
    }

    private func contentView(viewModel: DashboardViewModel) -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 16)

                    stressRingSection
                        .padding(.vertical, 24)

                    quickStatsRow
                        .padding(.horizontal)

                    if let insight = viewModel.aiInsight {
                        AIInsightCard(insight: insight) {
                            showingBreathing = true
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                        .frame(height: 80)
                }
            }
            .refreshable {
                await viewModel.refreshStressLevel()
            }

            floatingButton(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Stress Monitor")
                    .font(.largeTitle)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var stressRingSection: some View {
        VStack(spacing: 16) {
            if let viewModel = viewModel {
                StressRingView(
                    stressLevel: viewModel.currentStress?.level ?? 0,
                    category: viewModel.stressCategory
                )

                HStack(spacing: 8) {
                    Image(systemName: viewModel.stressCategory.icon)
                        .font(.title3)

                    Text(viewModel.stressCategory.rawValue.capitalized)
                        .font(.headline)
                }
                .foregroundColor(Color.stressColor(for: viewModel.stressCategory))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.stressColor(for: viewModel.stressCategory).opacity(0.15))
                .cornerRadius(20)

                if let confidence = viewModel.currentStress?.confidence {
                    HStack(spacing: 16) {
                        Label("\(Int(confidence * 100))% confident", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let updated = viewModel.lastUpdated {
                            Label("Updated \(relativeTime(updated))", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                icon: "heart.fill",
                value: "\(Int(viewModel?.todayHRV ?? 0))",
                unit: "ms",
                label: "Today's HRV",
                tintColor: .red
            )

            QuickStatCard(
                icon: "chart.xyaxis.lines",
                value: trendIcon,
                unit: "",
                label: "7-Day",
                tintColor: .stressRelaxed
            )

            QuickStatCard(
                icon: "scale.3d",
                value: formatBaselineRange(viewModel?.baseline),
                unit: "",
                label: "Baseline",
                tintColor: .primaryBlue
            )
        }
    }

    private func floatingButton(viewModel: DashboardViewModel) -> some View {
        VStack {
            Spacer()

            Button(action: { Task { await viewModel.measureNow() } }) {
                HStack {
                    if viewModel.isMeasuring {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.leading, 8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }

                    Text(viewModel.isMeasuring ? "Measuring..." : "Measure Now")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.isMeasuring ? Color.gray : Color.primaryBlue)
                .cornerRadius(26)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var trendIcon: String {
        guard let trend = viewModel?.weeklyTrend else { return "→" }
        switch trend {
        case .up: return "↑"
        case .down: return "↓"
        case .stable: return "→"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatBaselineRange(_ baseline: PersonalBaseline?) -> String {
        guard let baseline = baseline else { return "--" }
        return "\(Int(baseline.baselineHRV))"
    }

    private var breathingPlaceholder: some View {
        VStack(spacing: 20) {
            Text("Breathing Exercise")
                .font(.title)
                .padding()

            Text("This feature is coming soon!")
                .foregroundColor(.secondary)

            Button("Close") {
                showingBreathing = false
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StressMeasurement.self, configurations: config)
    return StressDashboardView()
        .modelContainer(container)
}

