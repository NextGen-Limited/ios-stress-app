import SwiftUI

// MARK: - Semicircular Gauge View

/// Semicircular gauge (180°) with 4 segments and character inside
/// Matches reference image design with grey gradient segments
struct SemicircularGaugeView: View {
    let stressLevel: Double
    let result: StressResult?
    let size: CGFloat

    init(stressLevel: Double, result: StressResult? = nil, size: CGFloat = 280) {
        self.stressLevel = stressLevel
        self.result = result
        self.size = size
    }

    private var hasData: Bool {
        stressLevel > 0
    }

    private var mood: StressBuddyMood {
        StressBuddyMood.from(stressLevel: stressLevel)
    }

    var body: some View {
        ZStack {
            // Semicircular arc background
            SemicircularArcBackground(size: size)

            // Character inside the arc
            VStack(spacing: 8) {
                if hasData {
                    StressBuddyIllustration(mood: mood, size: characterSize)
                        .padding(.top, 20)

                    Text(mood.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(moodColor)
                } else {
                    // No data state
                    Text("No Data")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "FF3B30")) // Red #FF3B30

                    StressBuddyIllustration(mood: .sleeping, size: characterSize * 0.8)
                        .padding(.top, 8)
                }
            }
        }
        .frame(width: size, height: size * 0.6)
    }

    private var characterSize: CGFloat {
        size * 0.35
    }

    private var moodColor: Color {
        guard hasData else { return Color.gray }
        switch mood {
        case .sleeping, .calm:
            return Color.Wellness.exerciseCyan
        case .concerned:
            return Color.Wellness.daylightYellow
        case .worried:
            return Color.stressModerate
        case .overwhelmed:
            return Color.stressHigh
        }
    }
}

// MARK: - Semicircular Arc Background

private struct SemicircularArcBackground: View {
    let size: CGFloat

    private let segmentColors: [Color] = [
        Color(hex: "8E8E93"), // Dark grey
        Color(hex: "AEAEB2"),
        Color(hex: "C7C7CC"),
        Color(hex: "D1D1D6")  // Light grey
    ]

    var body: some View {
        ZStack {
            // 4 segments of semicircle
            ForEach(0..<4, id: \.self) { index in
                SemicircularSegment(
                    startAngle: Angle(degrees: 180 + Double(index) * 45),
                    endAngle: Angle(degrees: 180 + Double(index + 1) * 45),
                    gradientColors: gradientColors(for: index)
                )
            }
        }
        .frame(width: size, height: size * 0.5)
    }

    private func gradientColors(for index: Int) -> [Color] {
        let startColor = segmentColors[min(index, segmentColors.count - 1)]
        let endColor = segmentColors[min(index + 1, segmentColors.count - 1)]
        return [startColor, endColor]
    }
}

// MARK: - Semicircular Segment Shape

private struct SemicircularSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let gradientColors: [Color]

    private var arcThickness: CGFloat { 16 }

    var body: some View {
        ArcShape(startAngle: startAngle, endAngle: endAngle)
            .stroke(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: arcThickness, lineCap: .butt)
            )
    }
}

// MARK: - Arc Shape

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2 - 8

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

// MARK: - Preview

#Preview("With Data") {
    VStack {
        SemicircularGaugeView(stressLevel: 65, result: nil)
    }
    .padding()
    .background(Color.backgroundLight)
}

#Preview("No Data") {
    VStack {
        SemicircularGaugeView(stressLevel: 0, result: nil)
    }
    .padding()
    .background(Color.backgroundLight)
}
