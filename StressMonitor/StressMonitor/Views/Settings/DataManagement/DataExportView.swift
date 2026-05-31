import SwiftUI
import SwiftData

/// Data export view with date range picker, format selection, and share sheet integration
struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: DataExportViewModel
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""

    init(viewModel: DataExportViewModel = DataExportViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            dateRangeSection
            dataSelectionSection
            formatSection
            previewSection
            exportProgressSection
            exportButtonSection
            recordsCountSection
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityLabel("Cancel export")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Export Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadPreviewData(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.dateRange) { _, _ in
            Task {
                await viewModel.loadPreviewData(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.format) { _, _ in
            Task {
                await viewModel.loadPreviewData(modelContext: modelContext)
            }
        }
    }

    private var dateRangeSection: some View {
        Section("Date Range") {
            Picker("Range", selection: $viewModel.dateRange) {
                ForEach(ExportDateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Date range selection")

            if viewModel.dateRange == .custom {
                DatePicker("Start Date", selection: $viewModel.customStartDate, displayedComponents: .date)
                    .accessibilityLabel("Start date")
                DatePicker("End Date", selection: $viewModel.customEndDate, displayedComponents: .date)
                    .accessibilityLabel("End date")
            }

            Text(viewModel.dateRangeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var dataSelectionSection: some View {
        Section("Data to Include") {
            Toggle("HRV Measurements", isOn: $viewModel.includeHRV)
                .accessibilityLabel("Include HRV measurements")

            Toggle("Heart Rate Data", isOn: $viewModel.includeHeartRate)
                .accessibilityLabel("Include heart rate data")

            Toggle("Stress Levels", isOn: $viewModel.includeStressLevels)
                .accessibilityLabel("Include stress levels")

            Toggle("Baseline Data", isOn: $viewModel.includeBaseline)
                .accessibilityLabel("Include baseline data")
        }
    }

    private var formatSection: some View {
        Section("Format") {
            Picker("File Format", selection: $viewModel.format) {
                Text("CSV").tag(ExportFormat.csv)
                Text("JSON").tag(ExportFormat.json)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("File format")

            Text(viewModel.formatDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if let preview = viewModel.previewData {
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("First \(preview.count) records will be exported")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(preview)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                        .lineLimit(5)
                }
            }
        }
    }

    @ViewBuilder
    private var exportProgressSection: some View {
        if viewModel.isExporting {
            Section {
                ExportProgressBarView(
                    progress: viewModel.exportProgress,
                    currentOperation: viewModel.currentOperation,
                    recordsProcessed: viewModel.recordsProcessed,
                    totalRecords: viewModel.totalRecords
                )
            }
        }
    }

    private var exportButtonSection: some View {
        Section {
            Button(action: {
                Task {
                    await performExport()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Exporting...")
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isExporting || !viewModel.hasValidSelection)
            .accessibilityLabel(viewModel.isExporting ? "Exporting data" : "Export data")
            .accessibilityHint(!viewModel.hasValidSelection ? "Select at least one data type to export" : "Double tap to start export")
        }
    }

    @ViewBuilder
    private var recordsCountSection: some View {
        if !viewModel.isExporting {
            Section {
                HStack {
                    Text("Records to Export")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.estimatedRecordCount)")
                        .fontWeight(.semibold)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func performExport() async {
        do {
            viewModel.isExporting = true
            defer { viewModel.isExporting = false }

            let url = try await viewModel.exportData(modelContext: modelContext)
            await MainActor.run {
                exportURL = url
                showingShareSheet = true
                HapticManager.shared.success()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                HapticManager.shared.error()
            }
        }
    }
}

/// View model for data export
@Observable
class DataExportViewModel {
    var dateRange: ExportDateRange = .month
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    var includeHRV: Bool = true
    var includeHeartRate: Bool = true
    var includeStressLevels: Bool = true
    var includeBaseline: Bool = false
    var format: ExportFormat = .csv

    var isExporting: Bool = false
    var exportProgress: Double = 0
    var currentOperation: String = ""
    var recordsProcessed: Int = 0
    var totalRecords: Int = 0

    private(set) var previewData: String?
    private(set) var estimatedRecordCount: Int = 0

    var hasValidSelection: Bool {
        includeHRV || includeHeartRate || includeStressLevels || includeBaseline
    }

    var dateRangeDescription: String {
        let calendar = Calendar.current
        let now = Date()

        switch dateRange {
        case .day:
            return "Last 24 hours"
        case .week:
            return "Last 7 days"
        case .month:
            return "Last 4 weeks"
        case .threeMonths:
            return "Last 3 months"
        case .all:
            return "All time"
        case .custom:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
    }

    var formatDescription: String {
        switch format {
        case .csv:
            return "Comma-separated values, compatible with Excel and Numbers"
        case .json:
            return "Structured data format, suitable for developers and backups"
        }
    }

    private var dateRangeBounds: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch dateRange {
        case .day:
            let start = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return (start, now)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .day, value: -28, to: now) ?? now
            return (start, now)
        case .threeMonths:
            let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return (start, now)
        case .all:
            return (Date.distantPast, now)
        case .custom:
            return (customStartDate, customEndDate)
        }
    }

    func loadPreviewData(modelContext: ModelContext) async {
        await MainActor.run {
            currentOperation = "Loading preview..."
        }

        // Simulate loading preview data
        let records = fetchRecords(modelContext: modelContext, limit: 3)
        estimatedRecordCount = fetchRecords(modelContext: modelContext, limit: nil).count

        await MainActor.run {
            if format == .csv {
                previewData = generateCSVPreview(records: records)
            } else {
                previewData = generateJSONPreview(records: records)
            }
            currentOperation = ""
        }
    }

    func exportData(modelContext: ModelContext) async throws -> URL {
        let records = fetchRecords(modelContext: modelContext, limit: nil)
        totalRecords = records.count
        recordsProcessed = 0
        exportProgress = 0

        let fileName = "stress_export_\(Int(Date().timeIntervalSince1970))"
        let fileExtension = format == .csv ? "csv" : "json"

        guard let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw ExportError.fileAccessFailed
        }

        let fileURL = tempDir.appendingPathComponent("\(fileName).\(fileExtension)")

        await MainActor.run {
            currentOperation = "Generating \(fileExtension.uppercased())..."
        }

        let content: String
        if format == .csv {
            content = try await generateCSV(records: records)
        } else {
            content = try await generateJSON(records: records)
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        await MainActor.run {
            exportProgress = 1.0
            currentOperation = "Export complete"
        }

        return fileURL
    }

    private func fetchRecords(modelContext: ModelContext, limit: Int?) -> [StressMeasurement] {
        let (start, end) = dateRangeBounds

        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate { measurement in
                measurement.timestamp >= start && measurement.timestamp <= end
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            var results = try modelContext.fetch(descriptor)
            if let limit = limit {
                results = Array(results.prefix(limit))
            }
            return results
        } catch {
            return []
        }
    }

    private func generateCSVPreview(records: [StressMeasurement]) -> String {
        guard !records.isEmpty else { return "No data to export" }

        var csv = "Timestamp,HRV,Heart Rate,Stress Level,Confidence\n"
        for record in records {
            let formatter = ISO8601DateFormatter()
            csv += "\(formatter.string(from: record.timestamp)),"
            csv += "\(String(format: "%.1f", record.hrv)),"
            csv += "\(String(format: "%.0f", record.restingHeartRate)),"
            csv += "\(String(format: "%.0f", record.stressLevel)),"
            csv += "\(String(format: "%.2f", (record.confidences?.first ?? 0.0)))\n"
        }
        return csv
    }

    private func generateJSONPreview(records: [StressMeasurement]) -> String {
        guard !records.isEmpty else { return "No data to export" }

        let previewRecords = Array(records.prefix(2))
        let dict = previewRecords.map { record in
            [
                "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                "hrv": record.hrv,
                "heartRate": record.restingHeartRate,
                "stressLevel": record.stressLevel,
                "confidence": (record.confidences?.first ?? 0.0)
            ]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let json = String(data: jsonData, encoding: .utf8) {
            return json
        }
        return "Error generating preview"
    }

    private func generateCSV(records: [StressMeasurement]) async throws -> String {
        var csv = "Timestamp,HRV,Heart Rate,Stress Level,Confidence\n"

        for (index, record) in records.enumerated() {
            await MainActor.run {
                recordsProcessed = index + 1
                exportProgress = Double(index + 1) / Double(records.count)
                currentOperation = "Processing record \(index + 1) of \(records.count)..."
            }

            let formatter = ISO8601DateFormatter()
            csv += "\(formatter.string(from: record.timestamp)),"
            csv += "\(String(format: "%.1f", record.hrv)),"
            csv += "\(String(format: "%.0f", record.restingHeartRate)),"
            csv += "\(String(format: "%.0f", record.stressLevel)),"
            csv += "\(String(format: "%.2f", (record.confidences?.first ?? 0.0)))\n"
        }

        return csv
    }

    private func generateJSON(records: [StressMeasurement]) async throws -> String {
        let dict = records.map { record in
            [
                "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                "hrv": record.hrv,
                "heartRate": record.restingHeartRate,
                "stressLevel": record.stressLevel,
                "confidence": (record.confidences?.first ?? 0.0)
            ]
        }

        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        guard let json = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return json
    }
}

/// ShareSheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        DataExportView()
    }
}
