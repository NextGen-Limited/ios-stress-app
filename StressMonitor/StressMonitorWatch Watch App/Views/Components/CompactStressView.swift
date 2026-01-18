import SwiftUI

struct CompactStressView: View {
  let stressLevel: Double
  let category: StressCategory

  var body: some View {
    ZStack {
      Circle()
        .stroke(colorForLevel(stressLevel), lineWidth: WatchDesignTokens.compactRingWidth)

      Circle()
        .trim(from: 0, to: stressLevel / 100)
        .stroke(
          colorForLevel(stressLevel),
          style: StrokeStyle(
            lineWidth: WatchDesignTokens.compactRingWidth,
            lineCap: .round
          )
        )
        .rotationEffect(.degrees(-90))
        .animation(.easeInOut(duration: 0.3), value: stressLevel)

      VStack(spacing: WatchDesignTokens.compactSpacing) {
        Text("\(Int(stressLevel))")
          .font(.system(size: WatchDesignTokens.compactValueSize))
          .fontWeight(.bold)
          .foregroundStyle(colorForLevel(stressLevel))

        Text(category.rawValue.capitalized)
          .font(.system(size: WatchDesignTokens.compactLabelSize))
          .foregroundStyle(.secondary)
      }
    }
    .frame(
      width: WatchDesignTokens.compactRingSize,
      height: WatchDesignTokens.compactRingSize
    )
  }

  private func colorForLevel(_ level: Double) -> Color {
    StressResult.category(for: level).color
  }
}
