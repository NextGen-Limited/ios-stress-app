import SwiftUI

// MARK: - HealthDataRow

/// Three-column behavioral metrics row: Exercise / Sleep / Daylight.
///
/// Unlike vitals (bio-signals), these are behaviors. Each item carries an
/// SF Symbol icon, a value with unit, a label, and a delta line. Good deltas
/// render in green per the spec's `.delta.good` class.
///
/// Spec reference: design/screens/04-home.html — `.health-data`.
struct HealthDataRow: View {
    let exerciseValue: String
    let exerciseUnit: String
    let exerciseDelta: String
    let exerciseDeltaGood: Bool

    let sleepValue: String
    let sleepUnit: String
    let sleepDelta: String
    let sleepDeltaGood: Bool

    let daylightValue: String
    let daylightUnit: String
    let daylightDelta: String
    let daylightDeltaGood: Bool

    init(
        exerciseValue: String, exerciseUnit: String = "m", exerciseDelta: String = "yesterday", exerciseDeltaGood: Bool = false,
        sleepValue: String, sleepUnit: String = "", sleepDelta: String = "+12m vs avg", sleepDeltaGood: Bool = true,
        daylightValue: String, daylightUnit: String = "m", daylightDelta: String = "on target", daylightDeltaGood: Bool = true
    ) {
        self.exerciseValue = exerciseValue
        self.exerciseUnit = exerciseUnit
        self.exerciseDelta = exerciseDelta
        self.exerciseDeltaGood = exerciseDeltaGood

        self.sleepValue = sleepValue
        self.sleepUnit = sleepUnit
        self.sleepDelta = sleepDelta
        self.sleepDeltaGood = sleepDeltaGood

        self.daylightValue = daylightValue
        self.daylightUnit = daylightUnit
        self.daylightDelta = daylightDelta
        self.daylightDeltaGood = daylightDeltaGood
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            healthItem(
                icon: "figure.run",
                value: exerciseValue, unit: exerciseUnit,
                label: "Exercise",
                delta: exerciseDelta, deltaGood: exerciseDeltaGood
            )
            healthItem(
                icon: "moon.zzz.fill",
                value: sleepValue, unit: sleepUnit,
                label: "Sleep",
                delta: sleepDelta, deltaGood: sleepDeltaGood
            )
            healthItem(
                icon: "sun.max.fill",
                value: daylightValue, unit: daylightUnit,
                label: "Daylight",
                delta: daylightDelta, deltaGood: daylightDeltaGood
            )
        }
        .padding(16)
        .background(Color.Wellness.adaptiveCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health data: Exercise \(exerciseValue)\(exerciseUnit), Sleep \(sleepValue), Daylight \(daylightValue)\(daylightUnit)")
    }

    // MARK: - Item

    private func healthItem(
        icon: String, value: String, unit: String,
        label: String, delta: String, deltaGood: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "777986"))
                .padding(.bottom, 2)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .tracking(-0.3)
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "777986"))
                }
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "777986"))
                .padding(.top, 1)

            Text(delta)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.2)
                .foregroundStyle(deltaGood ? Color.stressRelaxed : Color(hex: "777986"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("HealthDataRow") {
    VStack {
        HealthDataRow(
            exerciseValue: "23", exerciseDelta: "yesterday",
            sleepValue: "6h 50", sleepDelta: "+12m vs avg",
            daylightValue: "42", daylightDelta: "on target"
        )
        Spacer()
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
