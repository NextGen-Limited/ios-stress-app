import SwiftUI
import SwiftData

struct MeasurementHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel

    init() {
        _viewModel = State(initialValue: HistoryViewModel(
            modelContext: ModelContext(try! ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            timeRangeSelector

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.groupedMeasurements.isEmpty {
                    emptyState
                } else {
                    measurementsList
                }
            }
        }
        .background(Color.backgroundLight)
        .task {
            await viewModel.fetchMeasurements()
        }
        .onAppear {
            viewModel = HistoryViewModel(modelContext: modelContext)
        }
    }

    private var header: some View {
        HStack {
            Text("History")
                .font(Typography.largeTitle)

            Spacer()

            Button(action: {}) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var timeRangeSelector: some View {
        Picker("", selection: $viewModel.selectedTimeRange) {
            Text("24H").tag(TimeRange.twentyFourHours)
            Text("7D").tag(TimeRange.sevenDays)
            Text("4W").tag(TimeRange.fourWeeks)
            Text("3M").tag(TimeRange.threeMonths)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: viewModel.selectedTimeRange) { _, _ in
            Task { await viewModel.fetchMeasurements() }
        }
    }

    private var measurementsList: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(viewModel.groupedMeasurements.keys.sorted(by: >)), id: \.self) { groupKey in
                    Section {
                        ForEach(viewModel.groupedMeasurements[groupKey] ?? []) { measurement in
                            NavigationLink {
                                MeasurementDetailView(measurement: measurement)
                            } label: {
                                HistoryRowView(measurement: measurement)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteMeasurement(measurement)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(groupKey)
                            .font(Typography.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .background(Color.backgroundLight)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading measurements...")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Measurements")
                .font(Typography.title2)

            Text("Take a measurement to see your history")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {}) {
                Text("Measure Now")
                    .font(Typography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primaryBlue)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
