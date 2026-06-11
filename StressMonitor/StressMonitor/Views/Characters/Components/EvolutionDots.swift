import SwiftUI

struct EvolutionDots: View {
    let currentStage: EvolutionStage
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(EvolutionStage.allCases, id: \.self) { stage in
                Circle()
                    .fill(stage.sortOrder <= currentStage.sortOrder ? color : Color.secondary.opacity(0.22))
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Evolution stage: \(currentStage.displayName)")
    }
}
