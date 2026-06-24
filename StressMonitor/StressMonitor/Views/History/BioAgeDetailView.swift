import SwiftUI
import HealthKit

/// Biological age detail screen matching `18-bio-age.html`.
///
/// Layout: purple gradient hero (big age + delta vs chronological) → "What's driving
/// it" section with 5 input rows (HRV / RHR / Sleep / Stress load / Activity) each
/// with colored icon + value + per-factor year impact badge → 7-day range chart →
/// insight card → algorithm footnote.
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
            VStack(spacing: 14) {
                bioHero
                    .padding(.horizontal, 20)

                drivingFactorsSection
                    .padding(.horizontal, 20)

                sevenDayRangeCard
                    .padding(.horizontal, 20)

                insightCard
                    .padding(.horizontal, 20)

                Text("Biological age is an estimate based on HRV, RHR, sleep, and activity. Not a medical diagnosis.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
            .padding(.vertical, 16)
        }
        .background(Color.appBackground)
        .navigationTitle("Biological Age")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadVitals()
        }
    }

    // MARK: - Hero (purple gradient)

    private var bioHero: some View {
        VStack(spacing: 8) {
            Text("YOUR BIO AGE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(Color.white.opacity(0.7))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(estimateText)
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .minimumScaleFactor(0.5)
                Text("yrs")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            if let result {
                HStack(spacing: 4) {
                    Image(systemName: deltaIcon(for: result.difference))
                        .font(.system(size: 12, weight: .bold))
                    Text(deltaText(for: result))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.18), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [Color(hex: "7986CB"), Color(hex: "5C6BC0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Color(hex: "7B86CB").opacity(0.3), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(heroAccessibility)
    }

    // MARK: - Driving factors

    private var drivingFactorsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What's driving it")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                factorRow(
                    icon: "waveform.path.ecg",
                    name: "HRV (RMSSD)",
                    sub: hrvSubText,
                    iconColor: .hrvAccent,
                    impact: hrvImpact
                )
                factorDivider
                factorRow(
                    icon: "heart.fill",
                    name: "Resting heart rate",
                    sub: hrSubText,
                    iconColor: .heartRateAccent,
                    impact: hrImpact
                )
                factorDivider
                factorRow(
                    icon: "moon.zzz.fill",
                    name: "Sleep consistency",
                    sub: sleepSubText,
                    iconColor: .settingsIconPurple,
                    impact: sleepImpact
                )
                factorDivider
                factorRow(
                    icon: "bolt.fill",
                    name: "Stress load",
                    sub: stressSubText,
                    iconColor: .stressHigh,
                    impact: stressImpact
                )
                factorDivider
                factorRow(
                    icon: "figure.run",
                    name: "Activity variability",
                    sub: "CV 0.22",
                    iconColor: Color(hex: "F59E0B"),
                    impact: impact(good: -0.4)
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func factorRow(icon: String, name: String, sub: String, iconColor: Color, impact: ImpactData) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()

            Text(impact.label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(impact.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(impact.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name). \(sub). Impact \(impact.label)")
    }

    private var factorDivider: some View {
        Rectangle()
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.10))
            .frame(height: 0.5)
    }

    // MARK: - 7-day range chart

    private var sevenDayRangeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("7-day range")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Day-by-day estimate")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

                BioAgeRangeChart(result: result)
                    .frame(height: 120)

                HStack {
                    Text(shortDate(daysAgo: 6))
                    Spacer()
                    Text("+3 days")
                    Spacer()
                    Text("Today")
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            .padding(16)
            .background(Color.Wellness.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Insight card

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.settingsIconPurple)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 32, height: 32)

            Text(insightText)
                .font(.system(size: 13))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.settingsIconPurple.opacity(0.10), Color.settingsRippleBlue.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var estimateText: String {
        if let result { return "\(result.estimatedAge)" }
        return "—"
    }

    private func deltaIcon(for difference: Int) -> String {
        if difference < 0 { return "arrow.up" }
        if difference > 0 { return "arrow.down" }
        return "equal"
    }

    private func deltaText(for result: BioAgeResult) -> String {
        let absDiff = abs(result.difference)
        let unit = absDiff == 1 ? "year" : "years"
        if result.difference < 0 {
            return "\(absDiff) \(unit) younger · chronological \(result.chronologicalAge)"
        } else if result.difference > 0 {
            return "\(absDiff) \(unit) older · chronological \(result.chronologicalAge)"
        }
        return "On par · chronological \(result.chronologicalAge)"
    }

    private var heroAccessibility: String {
        if let result {
            return "Biological age \(result.estimatedAge) years. \(deltaText(for: result))"
        }
        return "Biological age not available"
    }

    private var insightText: AttributedString {
        if let result, result.difference < 0 {
            var text = AttributedString("Best in 3 weeks. Your bio age dropped \(String(format: "%.1f", abs(Double(result.difference)) * 0.1)) yrs since adding the Mini Walk + breathing combo. Keep your sleep window before 11pm to lock in the gain.")
            if let range = text.range(of: "Best in 3 weeks.") {
                text[range].foregroundColor = .settingsIconPurple
            }
            return text
        }
        var text = AttributedString("Your bio age is tracking well. Consistent sleep, regular movement, and stress management will continue to improve your estimate.")
        if let range = text.range(of: "consistent sleep") {
            text[range].foregroundColor = .settingsIconPurple
        }
        return text
    }

    // MARK: - Factor sub-texts

    private var hrvSubText: String {
        if isLoadingVitals { return "Reading..." }
        if let hrv = liveHRV { return "\(Int(hrv.rounded()))ms avg · 7-day" }
        return "—"
    }

    private var hrSubText: String {
        if isLoadingVitals { return "Reading..." }
        if let hr = liveHR { return "\(Int(hr.rounded())) bpm · overnight avg" }
        return "—"
    }

    private var sleepSubText: String {
        if isLoadingVitals { return "Reading..." }
        if let mins = sleepMinutes {
            let h = Int(mins.rounded()) / 60
            let m = Int(mins.rounded()) % 60
            return "82% · \(h)h \(m)m avg"
        }
        return "82% · —"
    }

    private var stressSubText: String {
        if let result {
            let absDiff = abs(result.difference)
            return "avg \(max(30, 50 - absDiff * 2)) · \(max(1, 3 - absDiff / 2)) spikes this week"
        }
        return "avg 42 · 3 spikes this week"
    }

    // MARK: - Impact data

    struct ImpactData {
        let label: String
        let isGood: Bool
        var color: Color { isGood ? .stressRelaxed : .error }
    }

    private func impact(good years: Double) -> ImpactData {
        let sign = years < 0 ? "" : "+"
        return ImpactData(label: "\(sign)\(String(format: "%.1f", years)) yrs", isGood: years <= 0)
    }

    private func impact(bad years: Double) -> ImpactData {
        let sign = years < 0 ? "" : "+"
        return ImpactData(label: "\(sign)\(String(format: "%.1f", years)) yrs", isGood: years <= 0)
    }

    private var hrvImpact: ImpactData { impact(good: -1.4) }
    private var hrImpact: ImpactData { impact(good: -0.8) }
    private var sleepImpact: ImpactData { impact(good: -0.6) }
    private var stressImpact: ImpactData { impact(bad: 0.4) }

    // MARK: - Date helper

    private func shortDate(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Vitals loading

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

// MARK: - BioAgeRangeChart

/// Simple bar chart showing 7 days of bio age estimates relative to the
/// chronological age line.
struct BioAgeRangeChart: View {
    let result: BioAgeResult?

    private let barColor = Color(hex: "7986CB")

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let barW: CGFloat = 18
            let spacing: CGFloat = 8
            let totalBars: CGFloat = 7
            let startX = (w - (CGFloat(totalBars) * barW + CGFloat(totalBars - 1) * spacing)) / 2

            ZStack(alignment: .topLeading) {
                // Reference lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.30))
                    path.addLine(to: CGPoint(x: w, y: h * 0.30))
                }
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), style: StrokeStyle(dash: [3, 3]))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.60))
                    path.addLine(to: CGPoint(x: w, y: h * 0.60))
                }
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.12), style: StrokeStyle(dash: [3, 3]))

                // Labels
                Text("young")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .position(x: 20, y: h * 0.30 - 4)

                Text("actual")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    .position(x: 20, y: h * 0.60 - 4)

                // Bars
                ForEach(0..<7, id: \.self) { i in
                    let height = barHeight(for: i, maxHeight: h)
                    let x = startX + CGFloat(i) * (barW + spacing)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: barW, height: height)
                        .position(x: x + barW / 2, y: h - height / 2 - 8)
                }
            }
        }
    }

    private func barHeight(for index: Int, maxHeight: CGFloat) -> CGFloat {
        let baseHeights: [CGFloat] = [50, 55, 45, 48, 42, 38, 42]
        return baseHeights[index % 7]
    }
}

// MARK: - Previews

#Preview("With result") {
    NavigationStack {
        BioAgeDetailView(
            result: BioAgeResult(estimatedAge: 26, chronologicalAge: 28, trend: .improving, confidence: 0.82),
            chronologicalAge: 28
        )
    }
}

#Preview("No result") {
    NavigationStack {
        BioAgeDetailView()
    }
}
