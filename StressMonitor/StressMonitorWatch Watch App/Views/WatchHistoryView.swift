import SwiftUI

/// Watch **History** screen — 7-day stress log.
///
/// Light canvas with:
///  - 3 stat cards (Avg / Best / Peak) showing numeric scores in tier colours
///  - A 7-day bar chart (tier-coloured bars, today outlined in accent-strong)
///  - A grouped reading list with 3pt tier bars, SF Pro Rounded scores, and
///    SF Mono timestamps
///  - An empty state featuring the Ripple otter + a "Measure Now" pill
struct WatchHistoryView: View {
    @Bindable var viewModel: WatchStressViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let readings: [SharedReading]

    /// Optional BioAge estimate shown in the header card.
    @State private var bioAgeResult: BioAgeResult?
    /// Selected time range (7D / 30D / 90D) for the chart and heatmap.
    @State private var selectedRange: HistoryRange = .week

    init(viewModel: WatchStressViewModel) {
        self.viewModel = viewModel
        self.readings = WatchSharedDataStore.shared.history7Days
    }

    var body: some View {
        Group {
            if readings.isEmpty {
                emptyState
            } else {
                filledContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WatchDesignTokens.canvas.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filled content

    private var filledContent: some View {
        ScrollView {
            VStack(spacing: WatchDesignTokens.Spacing.sm) {
                if let bioAge = bioAgeResult {
                    WatchBioAgeCardView(result: bioAge)
                }
                statRow
                rangePicker
                chartCard
                heatmapCard
                readingList
            }
            .padding(.horizontal, WatchDesignTokens.contentSidePadding)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Range picker

    private var rangePicker: some View {
        RangePickerRow(selectedRange: $selectedRange)
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("HEATMAP")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .tracking(0.06 * 8.5)
                .foregroundStyle(WatchDesignTokens.muted)
            CalendarHeatmapView(readings: heatmapReadings)
        }
        .padding(WatchDesignTokens.Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    /// Adapt `SharedReading` list into the `WatchStressMeasurement` shape
    /// the heatmap expects, filtered by the active range.
    private var heatmapReadings: [WatchStressMeasurement] {
        let cutoff = Date().addingTimeInterval(-Double(selectedRange.dayCount) * 24 * 3600)
        return readings
            .filter { $0.timestamp >= cutoff }
            .map { WatchStressMeasurement(
                timestamp: $0.timestamp,
                stressLevel: $0.level,
                hrv: 0,
                restingHeartRate: 0
            )}
    }

    // MARK: - Stat row (Avg / Best / Peak)

    private var statRow: some View {
        HStack(spacing: 4) {
            statCard(value: stats.avg, label: "Avg", category: stats.avgCategory)
            statCard(value: stats.best, label: "Best", category: stats.bestCategory)
            statCard(value: stats.peak, label: "Peak", category: stats.peakCategory)
        }
    }

    private func statCard(value: Int, label: String, category: StressCategory) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .tracking(-0.02 * 14)
                .foregroundStyle(category.inkColor)
            Text(label.uppercased())
                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                .tracking(0.04 * 7)
                .foregroundStyle(WatchDesignTokens.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    // MARK: - Bar chart card

    private var chartCard: some View {
        StressBarChart(entries: chartEntries)
            .frame(height: 56)
            .padding(.horizontal, 2)
    }

    // MARK: - Reading list (grouped-list lineage)

    private var readingList: some View {
        VStack(spacing: 0) {
            ForEach(Array(readings.prefix(8).enumerated()), id: \.element.id) { idx, reading in
                readingRow(reading)
                if idx < min(readings.count, 8) - 1 {
                    Divider()
                        .frame(height: WatchDesignTokens.hairlineThickness)
                        .background(WatchDesignTokens.separator)
                }
            }
        }
        .padding(.horizontal, WatchDesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: WatchDesignTokens.radiusCard, style: .continuous)
                .fill(WatchDesignTokens.surface)
        )
    }

    private func readingRow(_ reading: SharedReading) -> some View {
        let category = StressCategory.category(for: reading.level)
        return HStack(spacing: 7) {
            // 3pt tier bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(category.color)
                .frame(width: 3, height: 26)

            Text("\(Int(reading.level))")
                .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                .tracking(-0.02 * 15)
                .foregroundStyle(category.inkColor)
                .frame(minWidth: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(category.glyphLabel)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundStyle(WatchDesignTokens.ink)
                Text(timeLabel(for: reading.timestamp))
                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(WatchDesignTokens.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .accessibilityElement()
        .accessibilityLabel("\(category.displayName), score \(Int(reading.level)), \(timeLabel(for: reading.timestamp))")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            CharacterFaceView(creature: .ripple, category: .relaxed, size: 48, showsHalo: true)
            Text("No readings yet")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundStyle(WatchDesignTokens.ink)
            Text("Take your first measurement to start tracking.")
                .font(.system(size: 10, weight: .regular, design: .default))
                .foregroundStyle(WatchDesignTokens.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Spacer(minLength: 0)
            Button {
                Task { await viewModel.measureStress() }
            } label: {
                Text("Measure Now")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(
                        Capsule(style: .continuous)
                            .fill(WatchDesignTokens.accentStrong)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, WatchDesignTokens.contentSidePadding)
        .padding(.bottom, 10)
    }

    // MARK: - Derivations

    private var stats: (avg: Int, avgCategory: StressCategory, best: Int, bestCategory: StressCategory, peak: Int, peakCategory: StressCategory) {
        let levels = readings.map { $0.level }
        guard !levels.isEmpty else {
            return (0, .relaxed, 0, .relaxed, 0, .relaxed)
        }
        let avg = levels.reduce(0, +) / Double(levels.count)
        let best = levels.min() ?? 0
        let peak = levels.max() ?? 0
        return (
            Int(avg), StressCategory.category(for: avg),
            Int(best), StressCategory.category(for: best),
            Int(peak), StressCategory.category(for: peak)
        )
    }

    private var chartEntries: [StressBarChart.DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let symbols = Calendar.current.shortWeekdaySymbols
        // Build last 7 days oldest → newest.
        var entries: [StressBarChart.DayEntry] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayReadings = readings.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let level = dayReadings.isEmpty ? nil : dayReadings.map { $0.level }.reduce(0, +) / Double(dayReadings.count)
            let symbolIndex = calendar.component(.weekday, from: day) - 1
            let letter = String(symbols[symbolIndex].prefix(1))
            entries.append(.init(dayLabel: letter, level: level))
        }
        return entries
    }

    private func timeLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today · " + date.formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday · " + date.formatted(date: .omitted, time: .shortened)
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE · h:mm a"
        return fmt.string(from: date)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WatchHistoryView(viewModel: WatchStressViewModel())
    }
}
#endif
