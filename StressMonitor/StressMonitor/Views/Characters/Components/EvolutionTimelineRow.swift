import SwiftUI

struct EvolutionTimelineRow: View {
    let stage: EvolutionStage
    let requirement: EvolutionRequirement
    let isComplete: Bool
    let isCurrent: Bool
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isComplete ? color : Color.secondary.opacity(0.15))
                    .frame(width: 32, height: 32)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else if isCurrent {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 32, height: 32)
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(stage.displayName)
                    .font(Typography.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundStyle(isComplete || isCurrent ? Color.Wellness.adaptivePrimaryText : Color.Wellness.adaptiveSecondaryText)

                Text(requirement.description)
                    .font(Typography.caption2)
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.displayName), \(requirement.description)")
    }
}
