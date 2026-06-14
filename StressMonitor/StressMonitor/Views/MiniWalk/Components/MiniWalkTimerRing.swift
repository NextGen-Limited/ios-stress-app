import SwiftUI

/// Redesigned timer ring for the Mini Walk screen.
///
/// - Dark canvas center (#0A0A0F) instead of a solid blue circle.
/// - Gradient progress arc (#4FC3F7 → #0288D1) on a subtle system-gray track.
/// - SF Pro Rounded, 48 pt light-weight tabular numerals for the time display.
struct MiniWalkTimerRing: View {
    let progress: Double
    let timeDisplay: String
    let isRunning: Bool

    // Ring geometry — spec: 200 pt outer, 180 pt track
    private let outerSize: CGFloat = 200
    private let trackSize: CGFloat = 180
    private let lineWidth: CGFloat = 10

    // Ripple blue gradient tokens (matching HomeCharacterDesignTokens.Ripple)
    private let ringGradient = AngularGradient(
        colors: [
            Color(hex: "#4FC3F7"),
            Color(hex: "#29B6F6"),
            Color(hex: "#0288D1"),
            Color(hex: "#4FC3F7")
        ],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )

    var body: some View {
        ZStack {
            // Subtle outer glow ring
            Circle()
                .stroke(Color(hex: "#4FC3F7").opacity(0.06), lineWidth: 2)
                .frame(width: outerSize, height: outerSize)

            // Track ring — rgba(120,120,128,0.12)
            Circle()
                .stroke(
                    Color(red: 120/255, green: 120/255, blue: 128/255, opacity: 0.12),
                    style: StrokeStyle(lineWidth: lineWidth)
                )
                .frame(width: trackSize, height: trackSize)

            // Progress arc — gradient stroke, starts at top (-90°)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: trackSize, height: trackSize)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Center fill — dark canvas (NOT solid blue)
            Circle()
                .fill(HomeCharacterDesignTokens.darkCanvas)
                .frame(width: trackSize - lineWidth * 2 - 4, height: trackSize - lineWidth * 2 - 4)

            // Time text — SF Pro Rounded, 48 pt light, white #E0E0E8, tabular nums
            Text(timeDisplay)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundStyle(Color(hex: "#E0E0E8"))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.25), value: timeDisplay)
        }
        .frame(width: outerSize, height: outerSize)
        .accessibilityElement()
        .accessibilityLabel("Timer: \(timeDisplay) remaining")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

#Preview {
    VStack(spacing: 40) {
        MiniWalkTimerRing(progress: 0.0, timeDisplay: "10:00", isRunning: false)
        MiniWalkTimerRing(progress: 0.35, timeDisplay: "6:30", isRunning: true)
        MiniWalkTimerRing(progress: 0.95, timeDisplay: "0:30", isRunning: true)
    }
    .padding(40)
    .background(HomeCharacterDesignTokens.darkCanvas)
}
