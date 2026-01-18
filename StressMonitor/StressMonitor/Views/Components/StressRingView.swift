import SwiftUI

struct StressRingView: View {
    let level: Double
    let animate: Bool

    init(level: Double, animate: Bool = true) {
        self.level = min(max(level, 0), 100)
        self.animate = animate
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 30)

            Circle()
                .trim(from: 0, to: animate ? level / 100 : 0)
                .stroke(
                    colorForLevel(level),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: DesignTokens.Animation.slowDuration), value: animate ? level : 0)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("\(Int(level))")
                    .font(.system(size: DesignTokens.Typography.heroSize, weight: .bold))
                    .foregroundColor(colorForLevel(level))

                Text("STRESS")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 280, height: 280)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stress level")
        .accessibilityValue("\(Int(level)) out of 100")
    }

    private func colorForLevel(_ level: Double) -> Color {
        Color.stressColor(for: StressResult.category(for: level))
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.xl) {
        StressRingView(level: 15)
        StressRingView(level: 45)
        StressRingView(level: 70)
        StressRingView(level: 90)
    }
    .padding()
}
