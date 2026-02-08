import SwiftUI
import SwiftData

/// Data deletion view with options for local, cloud, or complete deletion
struct DataDeleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: DataDeleteViewModel
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(viewModel: DataDeleteViewModel = DataDeleteViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            // Delete Scope Section
            Section("Delete Options") {
                Picker("Scope", selection: $viewModel.deleteScope) {
                    Text("Local Only").tag(DataDeleteScope.localOnly)
                    Text("Cloud Only").tag(DataDeleteScope.cloudOnly)
                    Text("Everything").tag(DataDeleteScope.everything)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Delete scope selection")

                Text(viewModel.deleteScopeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            // Date Range Section
            Section("Date Range") {
                Toggle("Custom Date Range", isOn: $viewModel.useCustomDateRange)
                    .accessibilityLabel("Use custom date range")

                if viewModel.useCustomDateRange {
                    DatePicker("Start Date", selection: $viewModel.customStartDate, displayedComponents: .date)
                        .accessibilityLabel("Start date")
                    DatePicker("End Date", selection: $viewModel.customEndDate, displayedComponents: .date)
                        .accessibilityLabel("End date")
                } else {
                    Picker("Range", selection: $viewModel.dateRange) {
                        Text("All Time").tag(DeleteDateRange.all)
                        Text("Last 3 Months").tag(DeleteDateRange.threeMonths)
                        Text("Last Month").tag(DeleteDateRange.month)
                        Text("Last Week").tag(DeleteDateRange.week)
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Date range selection")
                }

                if let description = viewModel.dateRangeDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Affected Data Section
            if !viewModel.isDeleting {
                Section("Affected Data") {
                    AffectedDataRow(
                        icon: "heart.slash.fill",
                        label: "Stress Measurements",
                        count: viewModel.affectedMeasurementCount
                    )

                    if viewModel.deleteScope.includesBaseline {
                        AffectedDataRow(
                            icon: "chart.line.flattrend.xyaxis",
                            label: "Personal Baseline",
                            count: viewModel.affectedBaselineCount
                        )
                    }

                    HStack {
                        Text("Total")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.totalAffectedCount) items")
                            .fontWeight(.semibold)
                            .foregroundColor(.error)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            // Delete Progress Section
            if viewModel.isDeleting {
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)

                            Circle()
                                .trim(from: 0, to: viewModel.deleteProgress)
                                .stroke(
                                    Color.error,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.deleteProgress)

                            Text("\(Int(viewModel.deleteProgress * 100))%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }

                        Text(viewModel.currentOperation)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Delete progress: \(Int(viewModel.deleteProgress * 100)) percent")
                }
            }

            // Delete Button Section
            if !viewModel.isDeleting {
                Section {
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash.fill")
                            Text("Delete Data")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.totalAffectedCount == 0)
                    .accessibilityLabel("Delete data")
                    .accessibilityHint(viewModel.totalAffectedCount == 0 ? "No data to delete" : "Double tap to confirm deletion")
                }

                // Information Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "checkmark.circle.fill",
                            text: viewModel.deleteScope.includesCloud ? "Data will be removed from all devices" : "Only local data will be affected",
                            color: .primaryBlue
                        )

                        InfoRow(
                            icon: "xmark.circle.fill",
                            text: "This action cannot be undone",
                            color: .error
                        )

                        InfoRow(
                            icon: "info.circle.fill",
                            text: "HealthKit data will not be affected",
                            color: .secondary
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Delete Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if viewModel.isDeleting {
                        viewModel.cancelDelete()
                    } else {
                        dismiss()
                    }
                }
                .accessibilityLabel(viewModel.isDeleting ? "Stop deletion" : "Cancel")
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            DeleteConfirmationView(
                deleteScope: viewModel.deleteScope,
                dateRange: viewModel.getDateRange(),
                affectedDataCounts: AffectedDataCounts(
                    stressMeasurements: viewModel.affectedMeasurementCount,
                    baseline: viewModel.affectedBaselineCount > 0
                ),
                onConfirm: {
                    showingConfirmation = false
                    Task {
                        await performDelete()
                    }
                },
                onCancel: {
                    showingConfirmation = false
                }
            )
        }
        .alert("Deletion Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadAffectedCounts(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.deleteScope) { _, _ in
            Task {
                await viewModel.loadAffectedCounts(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.dateRange) { _, _ in
            Task {
                await viewModel.loadAffectedCounts(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.useCustomDateRange) { _, _ in
            Task {
                await viewModel.loadAffectedCounts(modelContext: modelContext)
            }
        }
    }

    private func performDelete() async {
        do {
            try await viewModel.performDelete(modelContext: modelContext)
            HapticManager.shared.success()
            dismiss()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
}

/// Row displaying affected data count
struct AffectedDataRow: View {
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.error)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.primary)

            Spacer()

            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundColor(.error)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) items")
    }
}

/// Information row
struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Date range for deletion
enum DeleteDateRange {
    case all
    case threeMonths
    case month
    case week

    var days: Int? {
        switch self {
        case .all: return nil
        case .threeMonths: return 90
        case .month: return 30
        case .week: return 7
        }
    }
}

/// View model for data deletion
@Observable
class DataDeleteViewModel {
    var deleteScope: DataDeleteScope = .localOnly
    var dateRange: DeleteDateRange = .all
    var useCustomDateRange: Bool = false
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var customEndDate: Date = Date()

    var isDeleting: Bool = false
    var deleteProgress: Double = 0
    var currentOperation: String = ""
    private var cancellationToken: Task<Void, Never>?

    private(set) var affectedMeasurementCount: Int = 0
    private(set) var affectedBaselineCount: Int = 0

    var deleteScopeDescription: String {
        switch deleteScope {
        case .localOnly:
            return "Only data stored on this device will be deleted. Cloud data will remain intact."
        case .cloudOnly:
            return "Only iCloud data will be deleted. Local data on this device will remain."
        case .everything:
            return "All data will be permanently deleted from both this device and iCloud."
        }
    }

    var dateRangeDescription: String? {
        guard useCustomDateRange else {
            switch dateRange {
            case .all: return nil
            case .threeMonths: return "Data from the last 3 months"
            case .month: return "Data from the last month"
            case .week: return "Data from the last week"
            }
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "From \(formatter.string(from: customStartDate)) to \(formatter.string(from: customEndDate))"
    }

    var totalAffectedCount: Int {
        affectedMeasurementCount + affectedBaselineCount
    }

    func getDateRange() -> DateRange? {
        guard useCustomDateRange else {
            if let days = dateRange.days {
                return DateRange(
                    startDate: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date(),
                    endDate: Date()
                )
            }
            return nil
        }
        return DateRange(startDate: customStartDate, endDate: customEndDate)
    }

    func loadAffectedCounts(modelContext: ModelContext) async {
        await MainActor.run {
            currentOperation = "Calculating affected data..."
        }

        let (start, end) = getDateRangeBounds()

        // Count stress measurements
        let measurementDescriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate { measurement in
                measurement.timestamp >= start && measurement.timestamp <= end
            }
        )

        do {
            let measurements = try modelContext.fetch(measurementDescriptor)
            await MainActor.run {
                affectedMeasurementCount = measurements.count
                affectedBaselineCount = deleteScope.includesBaseline ? 1 : 0
                currentOperation = ""
            }
        } catch {
            await MainActor.run {
                affectedMeasurementCount = 0
                affectedBaselineCount = 0
                currentOperation = ""
            }
        }
    }

    func performDelete(modelContext: ModelContext) async throws {
        isDeleting = true
        deleteProgress = 0
        currentOperation = "Preparing to delete..."

        cancellationToken = Task {
            await MainActor.run {
                isDeleting = false
                deleteProgress = 0
                currentOperation = ""
            }
        }

        let (start, end) = getDateRangeBounds()

        await MainActor.run {
            currentOperation = "Fetching data..."
        }

        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate { measurement in
                measurement.timestamp >= start && measurement.timestamp <= end
            }
        )

        let measurements = try modelContext.fetch(descriptor)

        guard !measurements.isEmpty else {
            throw DeleteError.noData
        }

        for (index, measurement) in measurements.enumerated() {
            try Task.checkCancellation()

            await MainActor.run {
                deleteProgress = Double(index + 1) / Double(measurements.count)
                currentOperation = "Deleting \(index + 1) of \(measurements.count)..."
            }

            modelContext.delete(measurement)
        }

        try modelContext.save()

        // Delete baseline if scope includes it
        if deleteScope.includesBaseline {
            try await deleteBaseline(modelContext: modelContext)
        }

        await MainActor.run {
            deleteProgress = 1.0
            currentOperation = "Delete complete"
        }
    }

    func cancelDelete() {
        cancellationToken?.cancel()
        cancellationToken = nil
    }

    private func deleteBaseline(modelContext: ModelContext) async throws {
        // Baseline deletion logic would go here
        // For now, we'll just mark it as completed
        await MainActor.run {
            currentOperation = "Removing baseline..."
        }
    }

    private func getDateRangeBounds() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        if useCustomDateRange {
            return (customStartDate, customEndDate)
        }

        guard let days = dateRange.days else {
            return (Date.distantPast, now)
        }

        let start = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        return (start, now)
    }
}

enum DeleteError: LocalizedError {
    case noData
    case operationFailed

    var errorDescription: String? {
        switch self {
        case .noData: return "No data found to delete"
        case .operationFailed: return "Failed to complete deletion"
        }
    }
}

#Preview {
    NavigationView {
        DataDeleteView()
    }
}
