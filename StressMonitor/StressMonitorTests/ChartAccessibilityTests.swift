import Testing
@testable import StressMonitor

/// Pins the D-09 chart trend-summary copy contract (A11Y-04): the one-line
/// VoiceOver entry for every fixed-size chart is
/// "{Metric} {up|down|steady} {percent}% in the last {period}", where the
/// steady variant omits the percent token. The builder is pure logic with
/// defined I/O, so the copy is unit-pinned red-first rather than eyeballed —
/// all five cases failed against the empty-string stub before any
/// implementation existed (plan 03-04 Task 1 RED proof).
@Suite("Chart Accessibility")
struct ChartAccessibilityTests {

    @Test("a single-point series yields a steady summary with no percent token")
    func singlePointSeriesYieldsSteadySummary() {
        let summary = VoiceOverLabels.trendSummary(metric: "HRV", values: [48], period: "7 days")

        #expect(summary == "HRV steady in the last 7 days")
    }

    @Test("an upward multi-point series yields the up variant with the percent rounded to a whole number")
    func upwardSeriesYieldsUpVariantWithWholeNumberPercent() {
        // (55 - 48) / 48 * 100 = 14.58…% — rounds to 15, does not truncate to 14.
        let summary = VoiceOverLabels.trendSummary(metric: "HRV", values: [48, 50, 52, 55], period: "7 days")

        #expect(summary == "HRV up 15% in the last 7 days")
    }

    @Test("a downward multi-point series yields the down variant")
    func downwardSeriesYieldsDownVariant() {
        // (50 - 62) / 62 * 100 = -19.35…% — rounds to 19.
        let summary = VoiceOverLabels.trendSummary(metric: "HRV", values: [62, 58, 55, 50], period: "7 days")

        #expect(summary == "HRV down 19% in the last 7 days")
    }

    @Test("an exactly-flat multi-point series yields the steady variant")
    func exactlyFlatSeriesYieldsSteadyVariant() {
        let summary = VoiceOverLabels.trendSummary(metric: "Stress", values: [50, 50, 50, 50], period: "7 days")

        #expect(summary == "Stress steady in the last 7 days")
    }

    @Test("a zero-percent change over multiple points yields steady, not up 0%")
    func zeroPercentChangeOverMultiplePointsYieldsSteady() {
        let summary = VoiceOverLabels.trendSummary(metric: "Stress", values: [50, 55, 50], period: "7 days")

        #expect(summary == "Stress steady in the last 7 days")
        #expect(!summary.contains("%"))
    }
}
