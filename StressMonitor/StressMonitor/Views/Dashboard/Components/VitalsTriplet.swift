import SwiftUI

// MARK: - VitalsTriplet

/// Three-column vitals row: HRV / Heart Rate / Respiratory Rate.
///
/// Each column shows a large value with unit, a label, and a small trend
/// context line so the number isn't naked. Separators between columns match
/// the spec's `.vitals` grid with `::before` divider lines.
///
/// Spec reference: design/screens/04-home.html — `.vitals`.
struct VitalsTriplet: View {
    let hrvValue: String
    let hrvUnit: String
    let hrvTrend: String?
    let hrvTrendGood: Bool

    let hrValue: String
    let hrUnit: String
    let hrTrend: String?
    let hrTrendGood: Bool

    let rrValue: String
    let rrUnit: String
    let rrTrend: String?
    let rrTrendGood: Bool

    init(
        hrvValue: String, hrvUnit: String = "ms", hrvTrend: String? = nil, hrvTrendGood: Bool = false,
        hrValue: String, hrUnit: String = "bpm", hrTrend: String? = nil, hrTrendGood: Bool = false,
        rrValue: String, rrUnit: String = "brpm", rrTrend: String? = nil, rrTrendGood: Bool = false
    ) {
        self.hrvValue = hrvValue
        self.hrvUnit = hrvUnit
        self.hrvTrend = hrvTrend
        self.hrvTrendGood = hrvTrendGood

        self.hrValue = hrValue
        self.hrUnit = hrUnit
        self.hrTrend = hrTrend
        self.hrTrendGood = hrTrendGood

        self.rrValue = rrValue
        self.rrUnit = rrUnit
        self.rrTrend = rrTrend
        self.rrTrendGood = rrTrendGood
    }

    var body: some View {
        HStack(spacing: 0) {
            vitalColumn(
                value: hrvValue, unit: hrvUnit, label: "HRV",
                trend: hrvTrend, trendGood: hrvTrendGood,
                accent: Color(hex: "34D399")
            )
            divider
            vitalColumn(
                value: hrValue, unit: hrUnit, label: "Heart",
                trend: hrTrend, trendGood: hrTrendGood,
                accent: Color(hex: "F87171")
            )
            divider
            vitalColumn(
                value: rrValue, unit: rrUnit, label: "Breath",
                trend: rrTrend, trendGood: rrTrendGood,
                accent: Color.stressMild
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vitals: HRV \(hrvValue) \(hrvUnit), Heart rate \(hrValue) \(hrUnit), Respiratory rate \(rrValue) \(rrUnit)")
    }

    // MARK: - Column

    private func vitalColumn(
        value: String, unit: String, label: String,
        trend: String?, trendGood: Bool, accent: Color
    ) -> some View {
        VStack(spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundStyle(accent)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "777986"))
            }

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.9)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "777986"))

            if let trend {
                Text(trend)
                    .font(.system(size: 10))
                    .foregroundStyle(trendGood ? Color.stressRelaxed : Color(hex: "777986"))
            } else {
                Text("")
                    .font(.system(size: 10))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: "3C3C43").opacity(0.12))
            .frame(width: 1, height: 50)
    }
}

// MARK: - Preview

#Preview("VitalsTriplet") {
    VStack {
        VitalsTriplet(
            hrvValue: "52", hrvTrend: "+8 vs avg", hrvTrendGood: true,
            hrValue: "68", hrTrend: "resting", hrTrendGood: false,
            rrValue: "14", rrTrend: "steady", rrTrendGood: false
        )
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}

#Preview("VitalsTriplet — No Data") {
    VStack {
        VitalsTriplet(
            hrvValue: "--",
            hrValue: "--",
            rrValue: "--"
        )
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
