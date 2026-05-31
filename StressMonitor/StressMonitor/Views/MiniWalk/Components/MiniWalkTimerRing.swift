import SwiftUI

struct MiniWalkTimerRing: View {
    let progress: Double
    let timeDisplay: String
    let isRunning: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let ringSize: CGFloat = 155
    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            // Decorative outer ring
            Circle()
                .stroke(Color.Wellness.miniWalkBlue.opacity(0.15), lineWidth: 2)
                .frame(width: 209, height: 209)

            // Track ring
            Circle()
                .stroke(
                    Color.Wellness.timerTrack,
                    style: StrokeStyle(lineWidth: lineWidth)
                )
                .frame(width: ringSize, height: ringSize)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.Wellness.miniWalkBlue,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Center filled circle
            Circle()
                .fill(Color.Wellness.miniWalkBlue)
                .frame(width: ringSize - lineWidth * 2 - 4, height: ringSize - lineWidth * 2 - 4)
                .shadow(color: .black.opacity(0.1), radius: 8.8, y: 4.4)

            // Time text
            Text(timeDisplay)
                .font(.custom("Roboto-Bold", size: 42))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}
