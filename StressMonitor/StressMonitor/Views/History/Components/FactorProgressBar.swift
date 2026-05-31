import SwiftUI

struct FactorProgressBar: View {
    let factor: ContributingFactor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(factor.name)
                    .font(Typography.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(factor.label)
                    .font(Typography.caption1)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(0..<10) { index in
                    let isFilled = Double(index) / 10.0 < factor.value
                    Circle()
                        .fill(isFilled ? colorForCategory(factor.category) : Color.secondary.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }

    private func colorForCategory(_ category: FactorCategory) -> Color {
        switch category {
        case .low: return .stressHigh
        case .normal: return .stressMild
        case .fair: return .stressModerate
        case .high: return .stressRelaxed
        }
    }
}
