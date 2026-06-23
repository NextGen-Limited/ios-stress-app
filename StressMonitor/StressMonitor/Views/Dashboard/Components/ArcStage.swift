import SwiftUI

// MARK: - ArcStage

/// Hero semicircular gauge (180 deg) following the 04-home spec.
///
/// A single half-arc track carries a gradient fill proportional to the stress
/// level (0-100). An endpoint tick marks the current reading. The Ripple
/// character sits inside the arc opening — the character IS the visual status.
/// Below the arc: state label, substate, and confidence line.
///
/// Spec reference: design/screens/04-home.html — `.hero` / `.arc-stage`.
struct ArcStage: View {
    let stressLevel: Double
    let result: StressResult?
    let measuredTime: Date?

    private let arcRadius: CGFloat = 70
    private let strokeWidth: CGFloat = 12

    init(stressLevel: Double, result: StressResult? = nil, measuredTime: Date? = nil) {
        self.stressLevel = stressLevel
        self.result = result
        self.measuredTime = measuredTime
    }

    var body: some View {
        VStack(spacing: 14) {
            arcContainer
            stateLabel
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "F2F7FF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: "007AFF").opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Arc with character

    private var arcContainer: some View {
        ZStack {
            SemicircleArcShape()
                .stroke(
                    Color(hex: "3C3C43").opacity(0.10),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )

            SemicircleArcShape()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    fillGradient,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )

            // Endpoint tick
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(tickOffset)

            // Character inside arc bowl
            StressBuddyIllustration(mood: mood, size: 70)
                .offset(y: 10)
        }
        .frame(width: 180, height: 100)
    }

    // MARK: - State label

    private var stateLabel: some View {
        VStack(spacing: 4) {
            Text(categoryDisplayName)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(categoryColor)
                .tracking(-0.75)

            if let sub = substateText {
                Text(sub)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "3C3C43"))
            }

            if let confidence = result?.confidence {
                Text(String(format: "%d%% confidence · 5-factor HRV", Int(confidence * 100)))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(Color(hex: "777986"))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Helpers

    private var clampedProgress: CGFloat {
        CGFloat(max(0, min(1, stressLevel / 100)))
    }

    private var categoryColor: Color {
        (result?.category ?? .relaxed).color
    }

    private var categoryDisplayName: String {
        result?.category.displayName.capitalized ?? "—"
    }

    private var substateText: String? {
        guard result != nil else { return nil }
        return mood.displayName + " · steady"
    }

    private var mood: RippleMood {
        RippleMood.from(stressLevel: stressLevel)
    }

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "2E9BFF"), Color(hex: "007AFF")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Position the endpoint tick on the semicircle at the current stress level.
    /// The arc goes from 180 deg to 360 deg (left to right over the top).
    /// At progress p, angle = 180 + p*180 degrees from +x axis.
    private var tickOffset: CGSize {
        let angle = Angle(degrees: 180 + Double(clampedProgress) * 180).radians
        let r = Double(arcRadius)
        return CGSize(width: cos(angle) * r, height: sin(angle) * r)
    }
}

// MARK: - Semicircle Arc Shape

/// A half-circle arc shape (180 deg) from left to right, used as the gauge
/// track and fill mask. Matches the SVG path `M 20 80 A 70 70 0 0 1 160 80`
/// from the spec — center-bottom, opening upward.
private struct SemicircleArcShape: Shape {
    var radius: CGFloat = 70

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY - 10)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )
        return path
    }
}

// MARK: - Preview

#Preview("ArcStage — Mild") {
    ArcStage(
        stressLevel: 42,
        result: StressResult(
            level: 42, category: .mild, confidence: 0.96,
            hrv: 52, heartRate: 68
        )
    )
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}

#Preview("ArcStage — Relaxed") {
    ArcStage(
        stressLevel: 15,
        result: StressResult(
            level: 15, category: .relaxed, confidence: 0.92,
            hrv: 68, heartRate: 60
        )
    )
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}

#Preview("ArcStage — No Data") {
    ArcStage(stressLevel: 0, result: nil)
        .padding()
        .background(HomeCharacterDesignTokens.homeBackground)
}
