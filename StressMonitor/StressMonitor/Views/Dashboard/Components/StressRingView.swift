import SwiftUI

struct StressRingView: View {
    let stressLevel: Double
    let category: StressCategory

    @State private var animateRing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.15),
                    lineWidth: 30
                )
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: animateRing ? stressLevel / 100 : 0)
                .stroke(
                    colorForCategory(category),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion
                        ? .linear(duration: 0.3)
                        : .spring(response: 0.6, dampingFraction: 0.7),
                    value: animateRing
                )

            VStack(spacing: 4) {
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 44))
                    .foregroundColor(colorForCategory(category))
                    .symbolEffect(.bounce, value: category)

                Text("\(Int(stressLevel))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(
                        reduceMotion
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
        .accessibilityValue("\(Int(stressLevel)) out of 100")
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateRing = true
            }
        }
        .onChange(of: stressLevel) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateRing = true
            }
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
