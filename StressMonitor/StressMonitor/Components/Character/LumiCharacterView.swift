import SwiftUI

/// Lumi — the Moon/Light Owl elemental creature.
///
/// - Design: radiant geometric body in indigo moonlight (no image assets).
///   Body fill #7986CB with radial highlight (#9FA8DA -> #5C6BC0).
///   Two tufted feather ears and a luminous halo; sparkle dots orbit the form.
///   Cheeks use a cool lilac at ~30% opacity.
///
/// - Mood rendering: each of the 8 `RippleMood` cases renders visibly
///   different eyes and mouth so the character reads at a glance.
struct LumiCharacterView: View {
    let mood: RippleMood
    var size: CGFloat = 120

    private let ink = Color(hex: "#1A237E")         // deep indigo for facial features
    private let cheekColor = Color(hex: "#B39DDB")
    private let sparkleColor = Color(hex: "#FFF59D")
    private let haloColor = Color(hex: "#C5CAE9")

    var body: some View {
        ZStack {
            // Luminous halo behind the body
            halo

            // Feather tuft ears
            earLayer

            // Main body — geometric moon form
            bodyLayer

            // Facial features
            faceLayer

            // Mood-specific light effects
            lightEffectLayer
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(mood.accessibilityLabel)
    }

    // MARK: - Halo

    private var halo: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [haloColor.opacity(0.0), haloColor.opacity(0.55), haloColor.opacity(0.0)],
                    center: .center
                ),
                lineWidth: size * 0.04
            )
            .frame(width: size * 0.96, height: size * 0.96)
            .accessibilityHidden(true)
    }

    // MARK: - Ears

    private var earLayer: some View {
        ZStack {
            tuftEar(side: -1)
            tuftEar(side: 1)
        }
    }

    private func tuftEar(side: CGFloat) -> some View {
        ZStack {
            TriangleTuft()
                .fill(HomeCharacterDesignTokens.Lumi.accent)
                .frame(width: size * 0.18, height: size * 0.26)
            TriangleTuft()
                .fill(Color(hex: "#9FA8DA").opacity(0.55))
                .frame(width: size * 0.10, height: size * 0.16)
        }
        .rotationEffect(.degrees(side > 0 ? 18 : -18))
        .offset(x: side * size * 0.28, y: -size * 0.28)
    }

    // MARK: - Body

    private var bodyLayer: some View {
        ZStack {
            // Slightly faceted body — rounded square for a geometric glow
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(moodBodyTint)
                .frame(width: size * 0.74, height: size * 0.74)

            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            HomeCharacterDesignTokens.Lumi.primary.opacity(0.85),
                            HomeCharacterDesignTokens.Lumi.accent.opacity(0.25)
                        ],
                        center: .center,
                        startRadius: size * 0.02,
                        endRadius: size * 0.38
                    )
                )
                .frame(width: size * 0.74, height: size * 0.74)

            // Radiant highlight
            Ellipse()
                .fill(Color.white.opacity(0.30))
                .frame(width: size * 0.22, height: size * 0.14)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.10, y: -size * 0.18)
        }
    }

    private var moodBodyTint: Color {
        switch mood {
        case .serene:      return HomeCharacterDesignTokens.Lumi.primary
        case .focused:     return HomeCharacterDesignTokens.Lumi.accent
        case .relaxed:     return HomeCharacterDesignTokens.Lumi.primary.opacity(0.92)
        case .happy:       return HomeCharacterDesignTokens.Lumi.primary
        case .celebrating: return HomeCharacterDesignTokens.Lumi.primary
        case .worried:     return Color(hex: "#5C6BC0").opacity(0.80)  // dimmed glow
        case .determined:  return HomeCharacterDesignTokens.Lumi.accent
        case .tired:       return Color(hex: "#7986CB").opacity(0.65)  // fading light
        }
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
        .offset(x: size * x, y: -size * 0.04)
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
        .offset(x: size * x, y: -size * 0.04)
    }

    private func halfClosedEye(x: CGFloat) -> some View {
        EyeArcShape(open: false)
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.018), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.07)
            .offset(x: size * x, y: -size * 0.02)
    }

    private func happyClosedEye(x: CGFloat) -> some View {
        HappyArcShape()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.08)
            .offset(x: size * x, y: -size * 0.03)
    }

    private func starEye(x: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.10))
            .foregroundStyle(sparkleColor)
            .offset(x: size * x, y: -size * 0.04)
    }

    private func xEye(x: CGFloat) -> some View {
        Text("\u{2715}")
            .font(.system(size: size * 0.14, weight: .heavy, design: .rounded))
            .foregroundStyle(ink)
            .offset(x: size * x, y: -size * 0.04)
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
        .offset(x: size * x, y: -size * 0.04)
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
        .offset(x: size * x, y: -size * 0.03)
    }

    // MARK: - Brows

    private func brow(x: CGFloat, angle: Double) -> some View {
        Capsule()
            .fill(ink)
            .frame(width: size * 0.12, height: size * 0.016)
            .rotationEffect(.degrees(angle))
            .offset(x: size * x, y: -size * 0.11)
    }

    // MARK: - Mouth Variants

    private func smileMouth(curvature: CGFloat, width: CGFloat) -> some View {
        SmilePath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * width, height: size * 0.10)
            .offset(y: size * 0.10)
    }

    private var wideSmileMouth: some View {
        SmilePath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.24, height: size * 0.12)
            .offset(y: size * 0.10)
    }

    private var bigSmileMouth: some View {
        ZStack {
            OpenSmileShape().fill(ink)
                .frame(width: size * 0.20, height: size * 0.12)
                .offset(y: size * 0.10)
            OpenSmileShape().fill(Color(hex: "#C5CAE9").opacity(0.5))
                .frame(width: size * 0.14, height: size * 0.06)
                .offset(y: size * 0.13)
        }
    }

    private var frownMouth: some View {
        FrownPath()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.16, height: size * 0.10)
            .offset(y: size * 0.13)
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
        .offset(y: size * 0.11)
    }

    private var flatMouth: some View {
        Capsule().fill(ink)
            .frame(width: size * 0.12, height: size * 0.018)
            .offset(y: size * 0.12)
    }

    // MARK: - Cheeks

    private var cheeks: some View {
        ZStack {
            Circle().fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: -size * 0.22, y: size * 0.05)
            Circle().fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: size * 0.22, y: size * 0.05)
        }
    }

    // MARK: - Light Effects

    @ViewBuilder
    private var lightEffectLayer: some View {
        switch mood {
        case .happy, .celebrating:
            sparkleOrbit
        case .worried, .tired:
            dimFlicker
        case .serene, .relaxed:
            gentleGlow
        default:
            EmptyView()
        }
    }

    private var sparkleOrbit: some View {
        ZStack {
            sparkleDot(at: CGPoint(x: 0.42, y: -0.22), sz: 0.06)
            sparkleDot(at: CGPoint(x: -0.40, y: -0.10), sz: 0.05)
            sparkleDot(at: CGPoint(x: 0.36, y: 0.24), sz: 0.05)
            sparkleDot(at: CGPoint(x: -0.34, y: 0.30), sz: 0.04)
        }
    }

    private func sparkleDot(at point: CGPoint, sz: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * sz))
            .foregroundStyle(sparkleColor)
            .offset(x: size * point.x, y: size * point.y)
    }

    private var dimFlicker: some View {
        // A single fading sparkle suggests waning light
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.05))
            .foregroundStyle(sparkleColor.opacity(0.4))
            .offset(x: size * 0.34, y: -size * 0.18)
    }

    private var gentleGlow: some View {
        ZStack {
            Circle().fill(sparkleColor.opacity(0.5))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: -size * 0.34, y: size * 0.22)
            Circle().fill(sparkleColor.opacity(0.3))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.36, y: size * 0.26)
        }
    }
}

// MARK: - Custom Shapes

private struct TriangleTuft: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.35)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.35)
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

#Preview("Lumi - All 8 Moods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(RippleMood.allCases, id: \.self) { mood in
                VStack(spacing: 8) {
                    LumiCharacterView(mood: mood, size: 120)
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
