import SwiftUI
import SwiftData

/// History timeline matching `11-history.html`.
///
/// Filter chips (All / Relaxed / Mild / Moderate / High) → summary tiles (avg 7d /
/// best / peak) → day-grouped entry cards with color bar, score, context, and time.
/// Tap row → push `MeasurementDetailView`.
struct MeasurementHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                loadingView
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Stress History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { HapticManager.shared.buttonPress() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.primaryBlue)
                }
                .accessibilityLabel("Filter")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
                await viewModel?.fetchMeasurements()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: HistoryViewModel) -> some View {
        if vm.isLoading && vm.measurements.isEmpty {
            loadingView
        } else if vm.measurements.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                filterChips(vm: vm)
                summaryTiles(vm: vm)
                timeline(vm: vm)
            }
        }
    }

    // MARK: - Filter chips

    private func filterChips(vm: HistoryViewModel) -> some View {
        VStack(spacing: 8) {
            // Date range chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(DateRangeFilter.allCases) { range in
                        DateFilterChip(range: range, selected: $vm.dateRange)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: vm.dateRange) {
                Task { await vm.fetchMeasurements() }
            }

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    allChip(vm: vm)
                    ForEach(StressCategory.allCases, id: \.self) { cat in
                        CategoryFilterChip(category: cat, selected: $vm.selectedCategories)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: vm.selectedCategories) {
                Task { await vm.fetchMeasurements() }
            }
        }
        .padding(.vertical, 8)
    }

    /// "All" chip that clears category filter. Shows count when active.
    private func allChip(vm: HistoryViewModel) -> some View {
        let isActive = vm.selectedCategories.isEmpty
        return Button {
            HapticManager.shared.buttonPress()
            vm.selectedCategories.removeAll()
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text("All · \(vm.measurements.count)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(isActive ? Color.white : Color.Wellness.adaptivePrimaryText)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                isActive
                    ? AnyShapeStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
                    : AnyShapeStyle(Color.Wellness.adaptiveCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.Wellness.adaptiveSecondaryText.opacity(0.28), lineWidth: 1)
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All categories")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    // MARK: - Summary tiles

    private func summaryTiles(vm: HistoryViewModel) -> some View {
        HStack(spacing: 8) {
            summaryTile(
                value: vm.averageScore7d.map { "\(Int($0))" } ?? "—",
                label: "avg · 7d",
                color: .stressMild
            )
            summaryTile(
                value: vm.bestScore.map { "\(Int($0.value))" } ?? "—",
                label: vm.bestScore.map { "best · \($0.label)" } ?? "best",
                color: .stressRelaxed
            )
            summaryTile(
                value: vm.peakScore.map { "\(Int($0.value))" } ?? "—",
                label: vm.peakScore.map { "peak · \($0.label)" } ?? "peak",
                color: .stressHigh
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func summaryTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(value)")
    }

    // MARK: - Timeline

    private func timeline(vm: HistoryViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: [.sectionHeaders]) {
                ForEach(vm.dayGroups) { group in
                    Section {
                        ForEach(group.measurements) { measurement in
                            NavigationLink {
                                MeasurementDetailView(measurement: measurement)
                            } label: {
                                HistoryEntryCard(measurement: measurement)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await vm.deleteMeasurement(measurement) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                            Spacer()
                            Text("\(group.count) reading\(group.count == 1 ? "" : "s")")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading measurements...")
                .font(.system(size: 14))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            Text("No Measurements")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text("Take a measurement to see your stress history here.")
                .font(.system(size: 14))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - HistoryEntryCard

/// Entry card matching `11-history.html` `.entry-card`: color bar + score/state +
/// context line + time.
struct HistoryEntryCard: View {
    let measurement: StressMeasurement

    private var category: StressCategory { measurement.category }

    var body: some View {
        HStack(spacing: 12) {
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.stressColor(for: category))
                .frame(width: 4, height: 36)

            // Body
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(measurement.stressLevel))")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.stressColor(for: category))
                    Text(category.rawValue.capitalized)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }

                Text("\(Int(measurement.hrv)) ms HRV")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.8))
            }

            Spacer()

            // Time
            Text(formatTime(measurement.timestamp))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Measurement at \(formatTime(measurement.timestamp)). Score \(Int(measurement.stressLevel)), \(category.rawValue.capitalized). HRV \(Int(measurement.hrv)) ms.")
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
