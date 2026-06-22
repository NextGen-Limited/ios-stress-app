import SwiftUI

/// Ember — the Fire/Phoenix elemental creature.
///
/// - Design: angular flame body in warm corals (no image assets).
///   Body fill #FFAB91 with radial highlight (#FFCCBC -> #FF8A65).
///   Flame tufts flicker above the head; pointed ear flames flank the body.
///   Cheeks use a deeper ember rose at ~30% opacity.
///
/// - Mood rendering: each of the 8 `RippleMood` cases renders visibly
///   different eyes and mouth so the character reads at a glance.
struct EmberCharacterView: View {
    let mood: RippleMood
    var size: CGFloat = 120

    private let ink = Color(hex: "#BF360C")         // deep ember for facial features
    private let cheekColor = Color(hex: "#FF8A80")
    private let flameTipColor = Color(hex: "#FFCCBC")

    var body: some View {
        ZStack {
            // Flame ears behind the body
            flameEarLayer

            // Main body — flame teardrop
            bodyLayer

            // Flame tufts on top
            flameTufts

            // Facial features
            faceLayer

            // Mood-specific ember effects
            emberEffectLayer
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(mood.accessibilityLabel)
    }

    // MARK: - Flame Ears

    private var flameEarLayer: some View {
        ZStack {
            flameEar(side: -1)
            flameEar(side: 1)
        }
    }

    private func flameEar(side: CGFloat) -> some View {
        FlameShape()
            .fill(HomeCharacterDesignTokens.Ember.accent)
            .frame(width: size * 0.20, height: size * 0.30)
            .rotationEffect(.degrees(side > 0 ? 28 : -28))
            .offset(x: side * size * 0.30, y: -size * 0.22)
    }

    // MARK: - Body

    private var bodyLayer: some View {
        FlameShape()
            .fill(moodBodyTint)
            .frame(width: size * 0.78, height: size * 0.86)
            .overlay(
                FlameShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeCharacterDesignTokens.Ember.primary.opacity(0.85),
                                HomeCharacterDesignTokens.Ember.accent.opacity(0.30)
                            ],
                            center: .center,
                            startRadius: size * 0.02,
                            endRadius: size * 0.42
                        )
                    )
                    .frame(width: size * 0.78, height: size * 0.86)
            )
            .overlay(
                // Glossy highlight
                Ellipse()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: size * 0.20, height: size * 0.12)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -size * 0.10, y: -size * 0.22)
            )
    }

    private var moodBodyTint: Color {
        switch mood {
        case .serene:      return HomeCharacterDesignTokens.Ember.primary
        case .focused:     return HomeCharacterDesignTokens.Ember.accent
        case .relaxed:     return HomeCharacterDesignTokens.Ember.primary.opacity(0.92)
        case .happy:       return HomeCharacterDesignTokens.Ember.primary
        case .celebrating: return HomeCharacterDesignTokens.Ember.primary
        case .worried:     return Color(hex: "#FFAB91").opacity(0.78)  // dimmed embers
        case .determined:  return HomeCharacterDesignTokens.Ember.accent
        case .tired:       return Color(hex: "#D7A89A")                // ashen embers
        }
    }

    // MARK: - Flame Tufts

    private var flameTufts: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let x: CGFloat = (CGFloat(index) - 1.0) * size * 0.14
                let h: CGFloat = index == 1 ? size * 0.24 : size * 0.18
                FlameShape()
                    .fill(flameTipColor)
                    .frame(width: size * 0.10, height: h)
                    .offset(x: x, y: -size * 0.36)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Face

    @ViewBuilder
    private var faceLayer: some View {
        switch mood {
        case .serene:      sereneFace
        case .focused:     focusedFace
        case .relaxed:     relaxedFace
        case .happy:       happyFace
        case .celebrating: celebratingFace
        case .worried:     worriedFace
        case .determined:  determinedFace
        case .tired:       tiredFace
        }
    }

    private var sereneFace: some View {
        ZStack {
            roundEye(x: -0.15)
            roundEye(x: 0.15)
            cheeks
            smileMouth(curvature: 0.35, width: 0.18)
        }
    }

    private var focusedFace: some View {
        ZStack {
            focusedEye(x: -0.15)
            focusedEye(x: 0.15)
            cheeks
            Ellipse()
                .stroke(ink, lineWidth: max(1.5, size * 0.018))
                .frame(width: size * 0.08, height: size * 0.06)
                .offset(y: size * 0.08)
        }
    }

    private var relaxedFace: some View {
        ZStack {
            halfClosedEye(x: -0.15)
            halfClosedEye(x: 0.15)
            cheeks
            wideSmileMouth
        }
    }

    private var happyFace: some View {
        ZStack {
            happyClosedEye(x: -0.15)
            happyClosedEye(x: 0.15)
            cheeks
            bigSmileMouth
        }
    }

    private var celebratingFace: some View {
        ZStack {
            starEye(x: -0.15)
            starEye(x: 0.15)
            cheeks
            bigSmileMouth
        }
    }

    private var worriedFace: some View {
        ZStack {
            xEye(x: -0.15)
            xEye(x: 0.15)
            brow(x: -0.15, angle: 12)
            brow(x: 0.15, angle: -12)
            frownMouth
        }
    }

    private var determinedFace: some View {
        ZStack {
            determinedEye(x: -0.15)
            determinedEye(x: 0.15)
            cheeks
            determinedMouth
        }
    }

    private var tiredFace: some View {
        ZStack {
            tiredEye(x: -0.15)
            tiredEye(x: 0.15)
            cheeks
            flatMouth
        }
    }

    // MARK: - Eye Variants

    private func roundEye(x: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(Color.white)
            Circle().fill(ink)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: size * 0.022, y: size * 0.028)
            Circle().fill(Color.white)
                .frame(width: size * 0.022, height: size * 0.022)
                .offset(x: size * 0.042, y: size * 0.038)
        }
        .frame(width: size * 0.13, height: size * 0.13)
        .offset(x: size * x, y: -size * 0.06)
    }

    private func focusedEye(x: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Ellipse().fill(moodBodyTint)
                .frame(width: size * 0.13, height: size * 0.13)
            Circle().fill(Color.white)
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: size * 0.03)
            Circle().fill(ink)
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: size * 0.015, y: size * 0.055)
        }
        .frame(width: size * 0.13, height: size * 0.13)
        .clipShape(Ellipse().size(width: size * 0.13, height: size * 0.10))
        .offset(x: size * x, y: -size * 0.06)
    }

    private func halfClosedEye(x: CGFloat) -> some View {
        EyeArcShape(open: false)
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.018), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.07)
            .offset(x: size * x, y: -size * 0.04)
    }

    private func happyClosedEye(x: CGFloat) -> some View {
        HappyArcShape()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.08)
            .offset(x: size * x, y: -size * 0.05)
    }

    private func starEye(x: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.10))
            .foregroundStyle(Color(hex: "#FFF176"))
            .offset(x: size * x, y: -size * 0.06)
    }

    private func xEye(x: CGFloat) -> some View {
        Text("\u{2715}")
            .font(.system(size: size * 0.14, weight: .heavy, design: .rounded))
            .foregroundStyle(ink)
            .offset(x: size * x, y: -size * 0.06)
    }

    private func determinedEye(x: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
            Circle().fill(ink)
                .frame(width: size * 0.055, height: size * 0.055)
                .offset(x: x > 0 ? -size * 0.015 : size * 0.015, y: size * 0.015)
        }
        .frame(width: size * 0.12, height: size * 0.12)
        .rotationEffect(.degrees(x > 0 ? -10 : 10))
        .offset(x: size * x, y: -size * 0.06)
    }

    private func tiredEye(x: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Circle().fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
            Capsule().fill(moodBodyTint)
                .frame(width: size * 0.14, height: size * 0.07)
                .offset(y: size * 0.015)
            Circle().fill(ink)
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(y: size * 0.045)
        }
        .frame(width: size * 0.12, height: size * 0.12)
        .offset(x: size * x, y: -size * 0.05)
    }

    // MARK: - Brows

    private func brow(x: CGFloat, angle: Double) -> some View {
        Capsule()
            .fill(ink)
            .frame(width: size * 0.12, height: size * 0.016)
            .rotationEffect(.degrees(angle))
            .offset(x: size * x, y: -size * 0.13)
    }

    // MARK: - Mouth Variants

    private func smileMouth(curvature: CGFloat, width: CGFloat) -> some View {
        SmilePath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * width, height: size * 0.10)
            .offset(y: size * 0.08)
    }

    private var wideSmileMouth: some View {
        SmilePath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.24, height: size * 0.12)
            .offset(y: size * 0.08)
    }

    private var bigSmileMouth: some View {
        ZStack {
            OpenSmileShape().fill(ink)
                .frame(width: size * 0.20, height: size * 0.12)
                .offset(y: size * 0.08)
            OpenSmileShape().fill(Color(hex: "#FFCDD2").opacity(0.5))
                .frame(width: size * 0.14, height: size * 0.06)
                .offset(y: size * 0.11)
        }
    }

    private var frownMouth: some View {
        FrownPath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.16, height: size * 0.10)
            .offset(y: size * 0.11)
    }

    private var determinedMouth: some View {
        Path { path in
            let waveWidth: CGFloat = size * 0.16
            let waveHeight: CGFloat = size * 0.03
            path.move(to: CGPoint(x: -waveWidth / 2, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: -waveHeight), control: CGPoint(x: -waveWidth * 0.25, y: -waveHeight))
            path.addQuadCurve(to: CGPoint(x: waveWidth / 2, y: 0), control: CGPoint(x: waveWidth * 0.25, y: -waveHeight))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
        .frame(width: size * 0.16, height: size * 0.06)
        .offset(y: size * 0.09)
    }

    private var flatMouth: some View {
        Capsule().fill(ink)
            .frame(width: size * 0.12, height: size * 0.018)
            .offset(y: size * 0.10)
    }

    // MARK: - Cheeks

    private var cheeks: some View {
        ZStack {
            Circle().fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: -size * 0.22, y: size * 0.03)
            Circle().fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: size * 0.22, y: size * 0.03)
        }
    }

    // MARK: - Ember Effects

    @ViewBuilder
    private var emberEffectLayer: some View {
        switch mood {
        case .happy, .celebrating:
            sparkBurst
        case .worried, .tired:
            // Smoke wisp indicates stress / fatigue
            smokeWisp
        case .determined:
            risingSparks
        default:
            EmptyView()
        }
    }

    private var sparkBurst: some View {
        ZStack {
            spark(at: CGPoint(x: 0.40, y: -0.22), sz: 0.07)
            spark(at: CGPoint(x: -0.38, y: -0.12), sz: 0.06)
            spark(at: CGPoint(x: 0.36, y: 0.22), sz: 0.05)
            spark(at: CGPoint(x: -0.32, y: 0.28), sz: 0.05)
        }
    }

    private var risingSparks: some View {
        ZStack {
            spark(at: CGPoint(x: 0.34, y: -0.30), sz: 0.06)
            spark(at: CGPoint(x: -0.34, y: -0.24), sz: 0.05)
        }
    }

    private func spark(at point: CGPoint, sz: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * sz))
            .foregroundStyle(Color(hex: "#FFD180"))
            .offset(x: size * point.x, y: size * point.y)
    }

    private var smokeWisp: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: size * 0.10))
            .foregroundStyle(Color.gray.opacity(0.35))
            .offset(x: size * 0.32, y: -size * 0.24)
    }
}

// MARK: - Custom Shapes

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = rect.midX
        // Pointed top, wavy sides, rounded bottom — flame silhouette
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.45),
            control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.18)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX + w * 0.18, y: rect.maxY - h * 0.08),
            control: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.22)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control: CGPoint(x: midX + w * 0.05, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX - w * 0.18, y: rect.maxY - h * 0.08),
            control: CGPoint(x: midX - w * 0.05, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.45),
            control: CGPoint(x: rect.minX, y: rect.maxY - h * 0.22)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + h * 0.18)
        )
        return path
    }
}

private struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct FrownPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

private struct OpenSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct EyeArcShape: Shape {
    var open: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = open ? rect.maxY : rect.maxY
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3),
            control: CGPoint(x: rect.midX, y: y)
        )
        return path
    }
}

private struct HappyArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

#Preview("Ember - All 8 Moods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(RippleMood.allCases, id: \.self) { mood in
                VStack(spacing: 8) {
                    EmberCharacterView(mood: mood, size: 120)
                    Text(mood.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }
    .background(HomeCharacterDesignTokens.homeBackground)
}
