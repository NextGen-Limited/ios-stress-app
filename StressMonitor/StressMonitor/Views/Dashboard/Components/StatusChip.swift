import SwiftUI

// MARK: - StatusChip

/// Pill-shaped status chips that sit below the hero arc in the home screen.
/// Two variants: bio-age estimate and streak counter. Both use the spec's
/// `.chip` class — pill shape, subtle background, SF Symbol icon, bold number.
///
/// Spec reference: design/screens/04-home.html — `.chip.bio-age` / `.chip.streak`.
struct StatusChip: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color

    init(icon: String, value: String, label: String, accentColor: Color) {
        self.icon = icon
        self.value = value
        self.label = label
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(-0.2)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "777986"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(accentColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Convenience Constructors

extension StatusChip {
    /// Bio-age estimate chip (e.g., "Bio age 24.5").
    static func bioAge(_ age: String) -> StatusChip {
        StatusChip(
            icon: "heart.text.square.fill",
            value: age,
            label: "bio age",
            accentColor: Color.stressMild
        )
    }

    /// Streak chip (e.g., "12-day streak").
    static func streak(_ days: String) -> StatusChip {
        StatusChip(
            icon: "flame.fill",
            value: days,
            label: "day streak",
            accentColor: Color(hex: "FF9500")
        )
    }
}

// MARK: - Preview

#Preview("StatusChips") {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            StatusChip.bioAge("24.5")
            StatusChip.streak("12")
        }
        HStack(spacing: 8) {
            StatusChip(icon: "moon.fill", value: "85%", label: "sleep score", accentColor: Color(hex: "5E5CE6"))
            StatusChip(icon: "figure.walk", value: "8,432", label: "steps", accentColor: Color.stressRelaxed)
        }
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
