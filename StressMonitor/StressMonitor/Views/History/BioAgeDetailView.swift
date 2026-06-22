import SwiftUI
import HealthKit

/// Detail screen for the biological-age estimate.
///
/// Displays the headline estimate + delta vs chronological age, the three live inputs
/// (HRV, resting heart rate, sleep) read from `HealthKitManager` (NOT from `BioAgeResult`,
/// which only carries the estimate + trend), a confidence indicator, and an algorithm
/// explainer. Reaches a `BioAgeResult` for the computed estimate when supplied.
struct BioAgeDetailView: View {
    var result: BioAgeResult?
    var chronologicalAge: Int?

    @State private var liveHRV: Double?
    @State private var liveHR: Double?
    @State private var sleepMinutes: Double?
    @State private var isLoadingVitals = true
    @Environment(\.dismiss) private var dismiss

    private let healthKit = HealthKitManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headlineCard
                inputsCard
                explainerCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground)
        .navigationTitle("Biological Age")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadVitals()
        }
    }

    // MARK: - Headline

    private var headlineCard: some View {
        VStack(spacing: 12) {
            Text("Estimated Bio Age")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(estimateText)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(estimateGradient)
                    .minimumScaleFactor(0.7)
                Text("years")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            if let result {
                Text(result.differenceLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor(for: result.difference))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor(for: result.difference).opacity(0.12), in: Capsule())
            }

            if let result {
                HStack(spacing: 6) {
                    Image(systemName: result.trend.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(result.trend.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headlineAccessibility)
    }

    // MARK: - Inputs

    private var inputsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Live inputs")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            if isLoadingVitals {
                HStack {
                    ProgressView()
                    Text("Reading Health…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                inputRow(
                    icon: "waveform.path.ecg",
                    label: "Heart Rate Variability",
                    value: liveHRV.map { "\(Int($0.rounded())) ms" } ?? "—",
                    tint: .stressRelaxed
                )
                hairlineDivider
                inputRow(
                    icon: "heart.fill",
                    label: "Resting Heart Rate",
                    value: liveHR.map { "\(Int($0.rounded())) bpm" } ?? "—",
                    tint: .heartRateAccent
                )
                hairlineDivider
                inputRow(
                    icon: "moon.zzz.fill",
                    label: "Sleep",
                    value: sleepText,
                    tint: .settingsIconPurple
                )
            }
        }
        .padding(18)
        .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), lineWidth: 1)
        )
    }

    private func inputRow(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(value)")
    }

    // MARK: - Explainer

    private var explainerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                Text("How this is calculated")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }

            Text("Ripple compares your live HRV, resting heart rate, and sleep against age-group norms. Higher HRV and lower resting heart rate push the estimate younger than your chronological age; poor sleep recovery pushes it older.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let result {
                confidenceRow(result.confidence)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), lineWidth: 1)
        )
    }

    private func confidenceRow(_ confidence: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Confidence")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                Spacer()
                Text("\(Int((confidence * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
                    Capsule()
                        .fill(HomeCharacterDesignTokens.Ripple.deep.opacity(0.8))
                        .frame(width: proxy.size.width * min(1, max(0.05, confidence)))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Helpers

    private var hairlineDivider: some View {
        Rectangle()
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
            .frame(height: 0.5)
    }

    private var estimateText: String {
        if let result { return "\(result.estimatedAge)" }
        return "—"
    }

    private var sleepText: String {
        guard let minutes = sleepMinutes else { return "—" }
        let hours = Int(minutes.rounded()) / 60
        let mins = Int(minutes.rounded()) % 60
        return "\(hours)h \(mins)m"
    }

    private var headlineAccessibility: String {
        var parts: [String] = []
        if let result {
            parts.append("Biological age \(result.estimatedAge) years")
            parts.append(result.differenceLabel)
            parts.append(result.trend.label)
        } else {
            parts.append("Biological age not available")
        }
        return parts.joined(separator: ", ")
    }

    private func accentColor(for difference: Int) -> Color {
        switch difference {
        case ...(-5): return HomeCharacterDesignTokens.Blossom.accent
        case -4 ... -1: return HomeCharacterDesignTokens.Ripple.primary
        case 0: return HomeCharacterDesignTokens.Ripple.mid
        case 1 ... 4: return HomeCharacterDesignTokens.Ember.accent
        default: return HomeCharacterDesignTokens.Ember.primary
        }
    }

    private var estimateGradient: LinearGradient {
        let accent = result.map { accentColor(for: $0.difference) } ?? HomeCharacterDesignTokens.Ripple.deep
        return LinearGradient(
            colors: [accent, accent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Vitals loading (G3: read from HealthKitManager, not BioAgeResult)

    private func loadVitals() async {
        isLoadingVitals = true
        defer { isLoadingVitals = false }

        guard HKHealthStore.isHealthDataAvailable() else { return }

        async let hrvTask = try? healthKit.fetchLatestHRV()?.value
        async let hrTask = try? healthKit.fetchHeartRate(samples: 1).first?.value
        async let sleepTask = try? await fetchSleepMinutes()

        let hrv = await hrvTask
        let hr = await hrTask
        let sleep = await sleepTask

        await MainActor.run {
            self.liveHRV = hrv
            self.liveHR = hr
            self.sleepMinutes = sleep
        }
    }

    private func fetchSleepMinutes() async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: []
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(
                sampleType: HKCategoryType(.sleepAnalysis),
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let sleepSamples = (samples as? [HKCategorySample]) ?? []
                let minutes = sleepSamples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                        || $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                        || $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                        || $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60 }
                continuation.resume(returning: minutes > 0 ? minutes : nil)
            }
            healthKit.healthStore.execute(query)
        }
    }
}

#Preview("With result") {
    NavigationStack {
        BioAgeDetailView(
            result: BioAgeResult(estimatedAge: 28, chronologicalAge: 35, trend: .improving, confidence: 0.82),
            chronologicalAge: 35
        )
    }
}

#Preview("No result") {
    NavigationStack {
        BioAgeDetailView()
    }
}
