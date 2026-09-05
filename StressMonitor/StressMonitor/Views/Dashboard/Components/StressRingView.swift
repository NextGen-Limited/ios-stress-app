import SwiftUI

struct StressRingView: View {
    let stressLevel: Double
    let category: StressCategory

    @State private var animateRing = false
    @State private var motionReduced = false

    private var trimFraction: Double {
        animateRing ? stressLevel / 100 : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 30
                )
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: trimFraction)
                .stroke(
                    colorForCategory(category),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animateIfMotionAllowed(
                    .spring(response: 0.6, dampingFraction: 0.7),
                    value: trimFraction
                )

            VStack(spacing: 4) {
                categoryIcon

                Text("\(Int(stressLevel))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(
                        motionReduced
                            ? .identity
                            : .numericText(countsDown: false)
                    )

                Text("STRESS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stress level")
        .accessibilityStressLevel(stressLevel, category: category)
        .onMotionDecision { motionReduced = $0 }
        .onAppear { animateRing = true }
    }

    @ViewBuilder
    private var categoryIcon: some View {
        let icon = Image(systemName: iconForCategory(category))
            .font(.system(size: 44))
            .foregroundColor(colorForCategory(category))
        if motionReduced {
            icon
        } else {
            icon.symbolEffect(.bounce, value: category)
        }
    }

    private func colorForCategory(_ category: StressCategory) -> Color {
        Color.stressColor(for: category)
    }

    private func iconForCategory(_ category: StressCategory) -> String {
        category.icon
    }
}

#Preview {
    VStack(spacing: 32) {
        StressRingView(stressLevel: 15, category: .relaxed)
        StressRingView(stressLevel: 45, category: .mild)
        StressRingView(stressLevel: 70, category: .moderate)
        StressRingView(stressLevel: 90, category: .high)
    }
    .padding()
}
