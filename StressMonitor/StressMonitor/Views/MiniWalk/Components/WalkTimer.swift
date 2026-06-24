import SwiftUI

/// Circular walk timer matching the `.timer-wrap` from `15-walk.html`.
///
/// Green progress ring (260pt), with a walk icon tile, large time display,
/// and "of X:XX target" subtitle centered. Pace and step count are surfaced
/// through the parent view's live-stats tiles.
struct WalkTimer: View {
    var progress: Double
    var timeDisplay: String
    var targetDisplay: String
    var stepCount: Int

    private let ringSize: CGFloat = 260
    private let lineWidth: CGFloat = 10
    private let ringColor = Color(hex: "#66BB6A")
    private let trackColor = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.08)
    private let walkIconGradient = [Color(hex: "#A5D6A7"), Color(hex: "#66BB6A")]
    private let fg = Color(hex: "#101223")
    private let muted = Color(hex: "#777986")

    var body: some View {
        ZStack {
            ringTrack
            ringProgress
            centerContent
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stepCount) steps, \(timeDisplay) of \(targetDisplay), \(Int((progress * 100).rounded())) percent complete")
    }

    private var ringTrack: some View {
        Circle()
            .stroke(trackColor, lineWidth: lineWidth)
    }

    private var ringProgress: some View {
        Circle()
            .trim(from: 0, to: min(1, max(0, progress)))
            .stroke(
                ringColor,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.3), value: progress)
    }

    private var centerContent: some View {
        VStack(spacing: 6) {
            // Walk icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: walkIconGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: ringColor.opacity(0.4), radius: 12, x: 0, y: 6)
                Image(systemName: "figure.walk")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Time display
            Text(timeDisplay)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .tracking(-0.02 * 56)
                .foregroundStyle(fg)
                .monospacedDigit()
                .contentTransition(.numericText())

            // Sub label
            Text("of \(targetDisplay) target")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(muted)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        WalkTimer(progress: 0.47, timeDisplay: "2:14", targetDisplay: "5:00", stepCount: 284)
        WalkTimer(progress: 0, timeDisplay: "0:00", targetDisplay: "5:00", stepCount: 0)
    }
    .padding(40)
    .background(Color(hex: "#F4FBF4"))
}
