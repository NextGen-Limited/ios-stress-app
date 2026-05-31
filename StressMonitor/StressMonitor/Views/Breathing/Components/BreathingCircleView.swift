import SwiftUI

struct BreathingCircleView: View {
    let phase: BreathingSessionViewModel.BreathingPhase
    let scale: Double
    let color: Color

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: breathingDuration).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .shadow(color: color.opacity(0.3), radius: 20)

            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 150, height: 150)
                .scaleEffect(scale)
                .blur(radius: 10)

            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    private var breathingDuration: Double {
        switch phase {
        case .inhale: return 4.0
        case .hold: return 1.0
        case .exhale: return 6.0
        }
    }
}
