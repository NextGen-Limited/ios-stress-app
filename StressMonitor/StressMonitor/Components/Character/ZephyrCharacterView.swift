import SwiftUI

/// Zephyr — the Air/Cloud Rabbit elemental creature.
///
/// - Design: wispy cloud-puff body in lavender mist (no image assets).
///   Body fill #D1C4E9 with radial highlight (#EDE7F6 -> #B39DDB).
///   Two long cloud-puff ears rise above; translucent side wisps trail off.
///   Cheeks use a soft lilac rose at ~30% opacity.
///
/// - Mood rendering: each of the 8 `RippleMood` cases renders visibly
///   different eyes and mouth so the character reads at a glance.
struct ZephyrCharacterView: View {
    let mood: RippleMood
    var size: CGFloat = 120

    private let ink = Color(hex: "#4527A0")         // deep lavender for facial features
    private let cheekColor = Color(hex: "#F48FB1")
    private let puffColor = Color(hex: "#EDE7F6")

    var body: some View {
        ZStack {
            // Wispy trail behind body
            wispyTrail

            // Cloud-puff ears
            earLayer

            // Main body — cloud puffs
            bodyLayer

            // Facial features
            faceLayer

            // Mood-specific air effects
            airEffectLayer
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(mood.accessibilityLabel)
    }

    // MARK: - Ears

    private var earLayer: some View {
        ZStack {
            cloudEar(side: -1)
            cloudEar(side: 1)
        }
    }

    private func cloudEar(side: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(HomeCharacterDesignTokens.Zephyr.accent.opacity(0.85))
                .frame(width: size * 0.16, height: size * 0.34)
            Capsule()
                .fill(puffColor.opacity(0.6))
                .frame(width: size * 0.08, height: size * 0.24)
        }
        .rotationEffect(.degrees(side > 0 ? 14 : -14))
        .offset(x: side * size * 0.24, y: -size * 0.30)
    }

    // MARK: - Body (cluster of cloud puffs)

    private var bodyLayer: some View {
        ZStack {
            // Base round form
            Circle()
                .fill(moodBodyTint)
                .frame(width: size * 0.78, height: size * 0.78)

            // Side puffs give the cloud silhouette
            Circle()
                .fill(moodBodyTint)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: -size * 0.30, y: size * 0.06)
            Circle()
                .fill(moodBodyTint)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.30, y: size * 0.06)
            Circle()
                .fill(moodBodyTint)
                .frame(width: size * 0.30, height: size * 0.30)
                .offset(x: 0, y: size * 0.28)

            // Radial highlight on the main puff
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            HomeCharacterDesignTokens.Zephyr.primary.opacity(0.85),
                            HomeCharacterDesignTokens.Zephyr.accent.opacity(0.20)
                        ],
                        center: .center,
                        startRadius: size * 0.02,
                        endRadius: size * 0.40
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)

            // Top-left glossy highlight
            Ellipse()
                .fill(Color.white.opacity(0.30))
                .frame(width: size * 0.22, height: size * 0.14)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.12, y: -size * 0.20)
        }
    }

    private var moodBodyTint: Color {
        switch mood {
        case .serene:      return HomeCharacterDesignTokens.Zephyr.primary
        case .focused:     return HomeCharacterDesignTokens.Zephyr.accent
        case .relaxed:     return HomeCharacterDesignTokens.Zephyr.primary.opacity(0.92)
        case .happy:       return HomeCharacterDesignTokens.Zephyr.primary
        case .celebrating: return HomeCharacterDesignTokens.Zephyr.primary
        case .worried:     return Color(hex: "#B39DDB").opacity(0.82)  // stormy lavender
        case .determined:  return HomeCharacterDesignTokens.Zephyr.accent
        case .tired:       return Color(hex: "#D1C4E9").opacity(0.7)   // thinning cloud
        }
    }

    private var wispyTrail: some View {
        ZStack {
            Circle()
                .fill(puffColor.opacity(0.35))
                .frame(width: size * 0.20, height: size * 0.20)
                .offset(x: -size * 0.44, y: size * 0.20)
            Circle()
                .fill(puffColor.opacity(0.22))
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: size * 0.46, y: size * 0.24)
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
            .foregroundStyle(Color(hex: "#FFF176"))
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
            OpenSmileShape().fill(Color(hex: "#E1BEE7").opacity(0.5))
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

    // MARK: - Air Effects

    @ViewBuilder
    private var airEffectLayer: some View {
        switch mood {
        case .happy, .celebrating:
            breezeSwirls
        case .worried, .tired:
            gustLines
        case .relaxed:
            floatDots
        default:
            EmptyView()
        }
    }

    private var breezeSwirls: some View {
        ZStack {
            breeze(at: CGPoint(x: 0.42, y: -0.20), sz: 0.07)
            breeze(at: CGPoint(x: -0.40, y: -0.08), sz: 0.06)
            breeze(at: CGPoint(x: 0.36, y: 0.26), sz: 0.05)
        }
    }

    private func breeze(at point: CGPoint, sz: CGFloat) -> some View {
        Image(systemName: "wind")
            .font(.system(size: size * sz))
            .foregroundStyle(puffColor)
            .offset(x: size * point.x, y: size * point.y)
    }

    private var gustLines: some View {
        ZStack {
            gust(at: CGPoint(x: 0.34, y: -0.24))
            gust(at: CGPoint(x: -0.34, y: -0.18))
        }
    }

    private func gust(at point: CGPoint) -> some View {
        Capsule()
            .fill(HomeCharacterDesignTokens.Zephyr.accent.opacity(0.4))
            .frame(width: size * 0.10, height: size * 0.02)
            .rotationEffect(.degrees(-18))
            .offset(x: size * point.x, y: size * point.y)
    }

    private var floatDots: some View {
        ZStack {
            Circle().fill(puffColor.opacity(0.5))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: -size * 0.34, y: size * 0.22)
            Circle().fill(puffColor.opacity(0.3))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.36, y: size * 0.26)
        }
    }
}

// MARK: - Custom Shapes

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

#Preview("Zephyr - All 8 Moods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(RippleMood.allCases, id: \.self) { mood in
                VStack(spacing: 8) {
                    ZephyrCharacterView(mood: mood, size: 120)
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
