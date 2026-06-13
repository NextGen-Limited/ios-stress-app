import SwiftUI

/// Reusable Ripple water-droplet character built entirely from SwiftUI shapes.
///
/// - Design: BLUE water droplet (no image assets).
///   Body fill #4FC3F7 with radial gradient overlay (#81D4FA → #0288D1).
///   Ears are ellipses (#29B6F6 with inner #0288D1 at 50% opacity).
///   Cheeks: #F48FB1 at ~30% opacity.
///
/// - Mood rendering: each of the 8 `RippleMood` cases renders visibly
///   different eyes and mouth so the character reads at a glance.
struct RippleCharacterView: View {
    let mood: RippleMood
    var size: CGFloat = 120

    private let ink = Color(hex: "#1A237E")     // deep indigo for facial features
    private let cheekColor = Color(hex: "#F48FB1")
    private let sparkleColor = Color(hex: "#B3E5FC")

    var body: some View {
        ZStack {
            // Ears sit behind the body
            earLayer

            // Main body — water droplet shape
            bodyLayer

            // Facial features
            faceLayer

            // Mood-specific water effects (sparkles, trails, sweat)
            waterEffectLayer
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(mood.accessibilityLabel)
    }

    // MARK: - Ears

    private var earLayer: some View {
        ZStack {
            ear(side: -1)
            ear(side: 1)
        }
    }

    private func ear(side: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#29B6F6"))
                .frame(width: size * 0.22, height: size * 0.26)
            Ellipse()
                .fill(HomeCharacterDesignTokens.Ripple.deep.opacity(0.5))
                .frame(width: size * 0.13, height: size * 0.16)
        }
        .offset(x: side * size * 0.30, y: -size * 0.30)
    }

    // MARK: - Body

    private var bodyLayer: some View {
        WaterDropletBody()
            .fill(mood.bodyTint)
            .frame(width: size * 0.72, height: size * 0.80)
            .overlay(
                // Radial gradient highlight (#81D4FA → #0288D1)
                WaterDropletBody()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeCharacterDesignTokens.Ripple.mid.opacity(0.8),
                                HomeCharacterDesignTokens.Ripple.deep.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: size * 0.02,
                            endRadius: size * 0.38
                        )
                    )
                    .frame(width: size * 0.72, height: size * 0.80)
            )
            .overlay(
                // Top-left glossy highlight
                Ellipse()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: size * 0.22, height: size * 0.14)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -size * 0.12, y: -size * 0.20)
            )
    }

    // MARK: - Face

    @ViewBuilder
    private var faceLayer: some View {
        switch mood {
        case .serene:
            sereneFace
        case .focused:
            focusedFace
        case .relaxed:
            relaxedFace
        case .happy:
            happyFace
        case .celebrating:
            celebratingFace
        case .worried:
            worriedFace
        case .determined:
            determinedFace
        case .tired:
            tiredFace
        }
    }

    // -- Serene: soft round eyes, gentle smile
    private var sereneFace: some View {
        ZStack {
            roundEye(x: -0.15)
            roundEye(x: 0.15)
            cheeks
            smileMouth(curvature: 0.35, width: 0.18)
        }
    }

    // -- Focused: narrowed determined eyes, small straight mouth
    private var focusedFace: some View {
        ZStack {
            focusedEye(x: -0.15)
            focusedEye(x: 0.15)
            cheeks
            // Small "o" determined mouth
            Ellipse()
                .stroke(ink, lineWidth: max(1.5, size * 0.018))
                .frame(width: size * 0.08, height: size * 0.06)
                .offset(y: size * 0.08)
        }
    }

    // -- Relaxed: half-closed content eyes, wide relaxed smile
    private var relaxedFace: some View {
        ZStack {
            halfClosedEye(x: -0.15)
            halfClosedEye(x: 0.15)
            cheeks
            wideSmileMouth
        }
    }

    // -- Happy: closed-happy (^ ^) eyes, big open smile
    private var happyFace: some View {
        ZStack {
            happyClosedEye(x: -0.15)
            happyClosedEye(x: 0.15)
            cheeks
            bigSmileMouth
        }
    }

    // -- Celebrating: wide star eyes, open happy mouth with sparkle
    private var celebratingFace: some View {
        ZStack {
            starEye(x: -0.15)
            starEye(x: 0.15)
            cheeks
            bigSmileMouth
        }
    }

    // -- Worried: X-eyes, frown mouth, raised brows
    private var worriedFace: some View {
        ZStack {
            xEye(x: -0.15)
            xEye(x: 0.15)
            // Raised worried brows
            brow(x: -0.15, angle: 12)
            brow(x: 0.15, angle: -12)
            frownMouth
            sweatDrop
        }
    }

    // -- Determined: angled sharp eyes, tight determined mouth
    private var determinedFace: some View {
        ZStack {
            determinedEye(x: -0.15)
            determinedEye(x: 0.15)
            cheeks
            determinedMouth
        }
    }

    // -- Tired: drooping half-closed eyes, small flat mouth, sweat drop
    private var tiredFace: some View {
        ZStack {
            tiredEye(x: -0.15)
            tiredEye(x: 0.15)
            cheeks
            flatMouth
            sweatDrop
        }
    }

    // MARK: - Eye Variants

    /// Open round eyes with white sclera + dark pupil + highlight.
    private func roundEye(x: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(Color.white)
            Circle()
                .fill(ink)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: size * 0.022, y: size * 0.028)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.022, height: size * 0.022)
                .offset(x: size * 0.042, y: size * 0.038)
        }
        .frame(width: size * 0.13, height: size * 0.13)
        .offset(x: size * x, y: -size * 0.06)
    }

    /// Focused: half-lidded with smaller pupil visible at bottom.
    private func focusedEye(x: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Upper lid covers top half
            Ellipse()
                .fill(mood.bodyTint)
                .frame(width: size * 0.13, height: size * 0.13)
            // Lower visible portion
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: size * 0.03)
            Circle()
                .fill(ink)
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: size * 0.015, y: size * 0.055)
        }
        .frame(width: size * 0.13, height: size * 0.13)
        .clipShape(Ellipse().size(width: size * 0.13, height: size * 0.10))
        .offset(x: size * x, y: -size * 0.06)
    }

    /// Half-closed content eyes: curved arcs.
    private func halfClosedEye(x: CGFloat) -> some View {
        EyeArcShape(open: false)
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.018), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.07)
            .offset(x: size * x, y: -size * 0.04)
    }

    /// Happy closed eyes: upward arcs (^ ^).
    private func happyClosedEye(x: CGFloat) -> some View {
        HappyArcShape()
            .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
            .frame(width: size * 0.12, height: size * 0.08)
            .offset(x: size * x, y: -size * 0.05)
    }

    /// Star eyes for celebrating: small star shapes.
    private func starEye(x: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: size * 0.10))
            .foregroundStyle(Color(hex: "#FFF176"))
            .offset(x: size * x, y: -size * 0.06)
    }

    /// X-eyes for worried.
    private func xEye(x: CGFloat) -> some View {
        ZStack {
            Text("✕")
                .font(.system(size: size * 0.14, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
        }
        .offset(x: size * x, y: -size * 0.06)
    }

    /// Determined: angled slash eyes looking inward.
    private func determinedEye(x: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
            Circle()
                .fill(ink)
                .frame(width: size * 0.055, height: size * 0.055)
                .offset(x: x > 0 ? -size * 0.015 : size * 0.015, y: size * 0.015)
        }
        .frame(width: size * 0.12, height: size * 0.12)
        .rotationEffect(.degrees(x > 0 ? -10 : 10))
        .offset(x: size * x, y: -size * 0.06)
    }

    /// Tired: heavy drooping eyelids, barely open.
    private func tiredEye(x: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Circle().fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
            // Heavy upper lid
            Capsule()
                .fill(mood.bodyTint)
                .frame(width: size * 0.14, height: size * 0.07)
                .offset(y: size * 0.015)
            Circle()
                .fill(ink)
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
            // Open mouth fill
            OpenSmileShape()
                .fill(ink)
                .frame(width: size * 0.20, height: size * 0.12)
                .offset(y: size * 0.08)
            // Tongue/highlight
            OpenSmileShape()
                .fill(Color(hex: "#E1BEE7").opacity(0.5))
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
        // Wavy determined mouth — slight grimace
        Path { p in
            let w: CGFloat = size * 0.16
            let h: CGFloat = size * 0.03
            p.move(to: CGPoint(x: -w / 2, y: 0))
            p.addQuadCurve(to: CGPoint(x: 0, y: -h), control: CGPoint(x: -w * 0.25, y: -h))
            p.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: w * 0.25, y: -h))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.020), lineCap: .round))
        .frame(width: size * 0.16, height: size * 0.06)
        .offset(y: size * 0.09)
    }

    private var flatMouth: some View {
        Capsule()
            .fill(ink)
            .frame(width: size * 0.12, height: size * 0.018)
            .offset(y: size * 0.10)
    }

    // MARK: - Cheeks

    private var cheeks: some View {
        ZStack {
            Circle()
                .fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: -size * 0.22, y: size * 0.03)
            Circle()
                .fill(cheekColor.opacity(0.32))
                .frame(width: size * 0.10, height: size * 0.07)
                .offset(x: size * 0.22, y: size * 0.03)
        }
    }

    // MARK: - Water Effects

    @ViewBuilder
    private var waterEffectLayer: some View {
        switch mood {
        case .happy, .celebrating:
            // Water sparkles around the character
            sparkles
        case .worried, .tired:
            // Sweat drop (rendered in face layer)
            EmptyView()
        case .relaxed:
            // Water trail particles (subtle)
            waterTrail
        default:
            EmptyView()
        }
    }

    private var sparkles: some View {
        ZStack {
            sparkle(at: CGPoint(x: 0.40, y: -0.20), sz: 0.06)
            sparkle(at: CGPoint(x: -0.38, y: -0.10), sz: 0.05)
            sparkle(at: CGPoint(x: 0.35, y: 0.22), sz: 0.04)
            sparkle(at: CGPoint(x: -0.30, y: 0.30), sz: 0.04)
        }
    }

    private func sparkle(at point: CGPoint, sz: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * sz))
            .foregroundStyle(sparkleColor)
            .offset(x: size * point.x, y: size * point.y)
    }

    private var waterTrail: some View {
        ZStack {
            Circle()
                .fill(sparkleColor.opacity(0.5))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: -size * 0.35, y: size * 0.20)
            Circle()
                .fill(sparkleColor.opacity(0.3))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.38, y: size * 0.25)
        }
    }

    private var sweatDrop: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: size * 0.07))
            .foregroundStyle(Color(hex: "#81D4FA"))
            .offset(x: size * 0.30, y: -size * 0.15)
    }
}

// MARK: - Custom Shapes

/// Teardrop/water-droplet body shape with pointed top and round bottom.
private struct WaterDropletBody: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = rect.midX
        let top = rect.minY + h * 0.06   // slight rounding at very top
        let bot = rect.maxY

        // Pointed top → rounded bottom
        path.move(to: CGPoint(x: midX, y: top))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.50),
            control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: bot),
            control: CGPoint(x: rect.maxX, y: bot - h * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.50),
            control: CGPoint(x: rect.minX, y: bot - h * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: top),
            control: CGPoint(x: rect.minX, y: rect.minY + h * 0.15)
        )
        return path
    }
}

/// Generic smile arc (U shape).
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

/// Frown arc (inverted U).
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

/// Open happy smile (filled D shape rotated).
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

/// Half-closed eye arc — gentle downward curve.
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

/// Happy upward arc (^ shape for closed-happy eyes).
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

// MARK: - Preview

#Preview("Ripple - All 8 Moods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(RippleMood.allCases, id: \.self) { mood in
                VStack(spacing: 8) {
                    RippleCharacterView(mood: mood, size: 120)
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
