import SwiftUI

/// Circular walk timer ring with the step count centered and pace below.
///
/// The ring fills clockwise as the walk progresses (0–1). Step count renders large
/// in the center; pace (e.g. "2.1 mph") sits beneath. Nil-safe for step/pace.
struct WalkTimer: View {
    var progress: Double
    var stepCount: Int
    var paceDisplay: String?

    private let ringSize: CGFloat = 220
    private let lineWidth: CGFloat = 14
    private let ripplePrimary = HomeCharacterDesignTokens.Ripple.primary
    private let rippleDeep = HomeCharacterDesignTokens.Ripple.deep

    var body: some View {
        ZStack {
            ringTrack
            ringProgress
            centerContent
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(centerAccessibility)
    }

    private var ringTrack: some View {
        Circle()
            .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
    }

    private var ringProgress: some View {
        Circle()
            .trim(from: 0, to: min(1, max(0, progress)))
            .stroke(
                AngularGradient(
                    colors: [ripplePrimary, rippleDeep, ripplePrimary],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 0.3), value: progress)
    }

    private var centerContent: some View {
        VStack(spacing: 6) {
            Text("\(stepCount)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(hex: "#E0E0E8"))
            Text("steps")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#9CA3AF"))
            if let paceDisplay, paceDisplay != "—" {
                Text(paceDisplay)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ripplePrimary)
                    .padding(.top, 2)
            }
        }
    }

    private var centerAccessibility: String {
        var parts = ["\(stepCount) steps"]
        if let paceDisplay, paceDisplay != "—" {
            parts.append(paceDisplay)
        }
        parts.append("\(Int((progress * 100).rounded())) percent complete")
        return parts.joined(separator: ", ")
    }
}

#Preview {
    VStack(spacing: 24) {
        WalkTimer(progress: 0.4, stepCount: 842, paceDisplay: "2.1 mph")
        WalkTimer(progress: 0, stepCount: 0, paceDisplay: nil)
    }
    .padding()
    .background(HomeCharacterDesignTokens.darkCanvas)
}
