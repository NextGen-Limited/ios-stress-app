import SwiftUI

/// SwiftUI vector interpretation of Ripple from the concept sheet.
/// This avoids blocking the Home redesign on the future 75-SVG asset pipeline.
struct RippleHomeCharacterGlyph: View {
    let mood: StressBuddyMood
    let size: CGFloat

    var body: some View {
        ZStack {
            waveLayer
                .offset(y: size * 0.18)

            otterBody
                .characterAnimation(for: mood)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var waveLayer: some View {
        ZStack {
            Capsule()
                .fill(HomeCharacterDesignTokens.Ripple.light.opacity(0.72))
                .frame(width: size * 0.84, height: size * 0.22)
                .rotationEffect(.degrees(-4))

            Capsule()
                .stroke(HomeCharacterDesignTokens.Ripple.primary.opacity(0.9), lineWidth: max(2, size * 0.035))
                .frame(width: size * 0.64, height: size * 0.16)
                .rotationEffect(.degrees(4))
                .offset(y: size * 0.03)
        }
    }

    private var otterBody: some View {
        ZStack {
            // Tail / water swoosh
            Capsule()
                .fill(HomeCharacterDesignTokens.Ripple.mid.opacity(0.62))
                .frame(width: size * 0.46, height: size * 0.18)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.22, y: size * 0.18)

            // Ears
            Circle()
                .fill(Color(hex: "#6F5643"))
                .frame(width: size * 0.20, height: size * 0.20)
                .offset(x: -size * 0.22, y: -size * 0.29)
            Circle()
                .fill(Color(hex: "#6F5643"))
                .frame(width: size * 0.20, height: size * 0.20)
                .offset(x: size * 0.22, y: -size * 0.29)

            // Head/body
            Circle()
                .fill(Color(hex: "#8A6A52"))
                .frame(width: size * 0.72, height: size * 0.72)
                .overlay(
                    Circle()
                        .fill(Color(hex: "#F0D8B8"))
                        .frame(width: size * 0.44, height: size * 0.34)
                        .offset(y: size * 0.14)
                )

            // Droplet belly
            WaterDropletShape()
                .fill(HomeCharacterDesignTokens.Ripple.light.opacity(0.95))
                .frame(width: size * 0.22, height: size * 0.28)
                .offset(y: size * 0.21)

            face

            // Paws
            Circle()
                .fill(Color(hex: "#6F5643"))
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: -size * 0.30, y: size * 0.14)
            Circle()
                .fill(Color(hex: "#6F5643"))
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: size * 0.30, y: size * 0.14)
        }
    }

    @ViewBuilder
    private var face: some View {
        switch mood {
        case .sleeping:
            sleepingFace
        case .calm:
            calmFace
        case .concerned:
            concernedFace
        case .worried:
            worriedFace
        case .overwhelmed:
            overwhelmedFace
        }
    }

    private var calmFace: some View {
        ZStack {
            eye(x: -0.14)
            eye(x: 0.14)
            nose
            SmileShape()
                .stroke(Color(hex: "#3B3028"), style: StrokeStyle(lineWidth: max(1.5, size * 0.016), lineCap: .round))
                .frame(width: size * 0.18, height: size * 0.10)
                .offset(y: size * 0.04)
            cheeks
        }
    }

    private var sleepingFace: some View {
        ZStack {
            closedEye(x: -0.14)
            closedEye(x: 0.14)
            nose
            Text("Z")
                .font(.system(size: size * 0.13, weight: .bold, design: .rounded))
                .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep.opacity(0.8))
                .offset(x: size * 0.25, y: -size * 0.20)
        }
    }

    private var concernedFace: some View {
        ZStack {
            eye(x: -0.14)
            eye(x: 0.14)
            nose
            Capsule()
                .fill(Color(hex: "#3B3028"))
                .frame(width: size * 0.12, height: size * 0.018)
                .offset(y: size * 0.08)
            cheeks
        }
    }

    private var worriedFace: some View {
        ZStack {
            eye(x: -0.14)
                .rotationEffect(.degrees(-7))
            eye(x: 0.14)
                .rotationEffect(.degrees(7))
            nose
            ArcMouthShape()
                .stroke(Color(hex: "#3B3028"), style: StrokeStyle(lineWidth: max(1.5, size * 0.016), lineCap: .round))
                .frame(width: size * 0.16, height: size * 0.08)
                .offset(y: size * 0.10)
        }
    }

    private var overwhelmedFace: some View {
        ZStack {
            Text("×")
                .font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#3B3028"))
                .offset(x: -size * 0.14, y: -size * 0.08)
            Text("×")
                .font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: "#3B3028"))
                .offset(x: size * 0.14, y: -size * 0.08)
            nose
            Circle()
                .stroke(Color(hex: "#3B3028"), lineWidth: max(1.5, size * 0.016))
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(y: size * 0.09)
        }
    }

    private func eye(x: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(.white)
            Circle()
                .fill(Color(hex: "#24232A"))
                .frame(width: size * 0.065, height: size * 0.065)
                .offset(x: size * 0.026, y: size * 0.032)
            Circle()
                .fill(.white)
                .frame(width: size * 0.025, height: size * 0.025)
                .offset(x: size * 0.050, y: size * 0.040)
        }
        .frame(width: size * 0.14, height: size * 0.14)
        .offset(x: size * x, y: -size * 0.08)
    }

    private func closedEye(x: CGFloat) -> some View {
        Capsule()
            .fill(Color(hex: "#3B3028"))
            .frame(width: size * 0.13, height: size * 0.018)
            .rotationEffect(.degrees(x < 0 ? 8 : -8))
            .offset(x: size * x, y: -size * 0.08)
    }

    private var nose: some View {
        Capsule()
            .fill(Color(hex: "#24232A"))
            .frame(width: size * 0.075, height: size * 0.055)
            .offset(y: size * 0.015)
    }

    private var cheeks: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#FFAAA7").opacity(0.75))
                .frame(width: size * 0.09, height: size * 0.055)
                .offset(x: -size * 0.26, y: size * 0.04)
            Circle()
                .fill(Color(hex: "#FFAAA7").opacity(0.75))
                .frame(width: size * 0.09, height: size * 0.055)
                .offset(x: size * 0.26, y: size * 0.04)
        }
    }
}

private struct WaterDropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.20), control2: CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.18), control2: CGPoint(x: rect.midX + rect.width * 0.22, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY), control1: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.maxY), control2: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.18))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.midY - rect.height * 0.04), control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.20))
        return path
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct ArcMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview("Ripple Moods") {
    HStack {
        ForEach(StressBuddyMood.allCases, id: \.self) { mood in
            RippleHomeCharacterGlyph(mood: mood, size: 100)
        }
    }
    .padding()
    .background(HomeCharacterDesignTokens.homeBackground)
}
