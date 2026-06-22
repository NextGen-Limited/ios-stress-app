import SwiftUI

/// Compact semicircular stress gauge for history rows and cards.
///
/// Renders a 60pt arc tinted by the stress category with the numeric score centered.
/// Nil-safe: a nil level renders an empty track.
struct StressGaugeMini: View {
    var level: Double?
    var category: StressCategory

    private let size: CGFloat = 60

    var body: some View {
        ZStack {
            gaugeArc
            if let level {
                VStack(spacing: 0) {
                    Text("\(Int(level.rounded()))")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.map { "Stress \($0)" } ?? "Stress unknown")
    }

    private var gaugeArc: some View {
        ZStack {
            Arc(progress: 1.0)
                .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.16), lineWidth: 6)
            if let level {
                Arc(progress: min(1, max(0, level / 100)))
                    .stroke(Color.stressColor(for: category), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            }
        }
    }
}

private struct Arc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = Angle.degrees(180)
        let end = Angle.degrees(180 + 180 * progress)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

#Preview {
    HStack {
        StressGaugeMini(level: 12, category: .relaxed)
        StressGaugeMini(level: 42, category: .mild)
        StressGaugeMini(level: 68, category: .moderate)
        StressGaugeMini(level: 88, category: .high)
        StressGaugeMini(level: nil, category: .mild)
    }
    .padding()
    .background(Color.appBackground)
}
