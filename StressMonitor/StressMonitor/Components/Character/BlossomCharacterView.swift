import SwiftUI

/// Blossom — the Earth/Forest Fox elemental creature.
///
/// - Design: soft round body in flora greens (no image assets).
///   Body fill #A5D6A7 with radial highlight (#C8E6C9 -> #81C784).
///   A petal crown of five rounded petals sits above the head; two leafy
///   ears flank the body. Cheeks use a warm rose at ~30% opacity.
///
/// - Mood rendering: each of the 8 `RippleMood` cases renders visibly
///   different eyes and mouth so the character reads at a glance.
struct BlossomCharacterView: View {
    let mood: RippleMood
    var size: CGFloat = 120

    private let ink = Color(hex: "#1B5E20")        // deep forest green for facial features
    private let cheekColor = Color(hex: "#F48FB1")
    private let petalColor = Color(hex: "#C8E6C9")

    var body: some View {
        ZStack {
            // Ears sit behind the body
            earLayer

            // Main body — round flora form
            bodyLayer

            // Petal crown above the head
            petalCrown

            // Facial features
            faceLayer

            // Mood-specific nature effects (leaves, sparkles, dew)
            natureEffectLayer
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(mood.accessibilityLabel)
    }

    // MARK: - Ears

    private var earLayer: some View {
        ZStack {
            leafEar(side: -1)
            leafEar(side: 1)
        }
    }

    private func leafEar(side: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(HomeCharacterDesignTokens.Blossom.accent)
                .frame(width: size * 0.18, height: size * 0.30)
            Capsule()
                .fill(petalColor.opacity(0.6))
                .frame(width: size * 0.10, height: size * 0.20)
        }
        .rotationEffect(.degrees(side > 0 ? 22 : -22))
        .offset(x: side * size * 0.28, y: -size * 0.26)
    }

    // MARK: - Body

    private var bodyLayer: some View {
        Circle()
            .fill(moodBodyTint)
            .frame(width: size * 0.78, height: size * 0.78)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                HomeCharacterDesignTokens.Blossom.primary.opacity(0.85),
                                HomeCharacterDesignTokens.Blossom.accent.opacity(0.25)
                            ],
                            center: .center,
                            startRadius: size * 0.02,
                            endRadius: size * 0.40
                        )
                    )
                    .frame(width: size * 0.78, height: size * 0.78)
            )
            .overlay(
                // Top-left glossy highlight
                Ellipse()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: size * 0.22, height: size * 0.14)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -size * 0.12, y: -size * 0.18)
            )
    }

    private var moodBodyTint: Color {
        switch mood {
        case .serene:      return HomeCharacterDesignTokens.Blossom.primary
        case .focused:     return HomeCharacterDesignTokens.Blossom.accent
        case .relaxed:     return HomeCharacterDesignTokens.Blossom.primary.opacity(0.92)
        case .happy:       return HomeCharacterDesignTokens.Blossom.primary
        case .celebrating: return HomeCharacterDesignTokens.Blossom.primary
        case .worried:     return Color(hex: "#AED581")   // slightly wilted
        case .determined:  return HomeCharacterDesignTokens.Blossom.accent
        case .tired:       return Color(hex: "#C5E1A5")   // paler, sleepy
        }
    }

    // MARK: - Petal Crown

    private var petalCrown: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                petal(index: index)
            }
        }
        .offset(y: -size * 0.42)
    }

    private func petal(index: Int) -> some View {
        let spacing: CGFloat = size * 0.13
        let x = (CGFloat(index) - 2.0) * spacing
        let isCenter = index == 2
        let h = isCenter ? size * 0.22 : size * 0.18
        return Capsule()
            .fill(petalColor)
            .frame(width: size * 0.10, height: h)
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: size * 0.04, height: h * 0.6)
            )
            .rotationEffect(.degrees(Double(index - 2) * -10))
            .offset(x: x, y: isCenter ? -size * 0.02 : 0)
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

    // -- Serene: soft round eyes, gentle smile
    private var sereneFace: some View {
        ZStack {
            roundEye(x: -0.15)
            roundEye(x: 0.15)
            cheeks
            smileMouth(curvature: 0.35, width: 0.18)
        }
    }

    // -- Focused: narrowed determined eyes, small "o" mouth
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

    // -- Celebrating: star eyes, open happy mouth
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
            brow(x: -0.15, angle: 12)
            brow(x: 0.15, angle: -12)
            frownMouth
        }
    }

    // -- Determined: angled sharp eyes, tight mouth
    private var determinedFace: some View {
        ZStack {
            determinedEye(x: -0.15)
            determinedEye(x: 0.15)
            cheeks
            determinedMouth
        }
    }

    // -- Tired: drooping half-closed eyes, small flat mouth
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

    private func focusedEye(x: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Ellipse()
                .fill(moodBodyTint)
                .frame(width: size * 0.13, height: size * 0.13)
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
            Circle()
                .fill(ink)
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
            Capsule()
                .fill(moodBodyTint)
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
            OpenSmileShape()
                .fill(ink)
                .frame(width: size * 0.20, height: size * 0.12)
                .offset(y: size * 0.08)
            OpenSmileShape()
                .fill(Color(hex: "#FFCDD2").opacity(0.5))
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

    // MARK: - Nature Effects

    @ViewBuilder
    private var natureEffectLayer: some View {
        switch mood {
        case .happy, .celebrating:
            floatingLeaves
        case .worried, .tired:
            // Single falling leaf indicates stress / fatigue
            fallingLeaf
        case .relaxed:
            dewDrops
        default:
            EmptyView()
        }
    }

    private var floatingLeaves: some View {
        ZStack {
            leaf(at: CGPoint(x: 0.40, y: -0.20), sz: 0.07, rotation: 18)
            leaf(at: CGPoint(x: -0.38, y: -0.10), sz: 0.06, rotation: -22)
            leaf(at: CGPoint(x: 0.35, y: 0.24), sz: 0.05, rotation: 30)
        }
    }

    private func leaf(at point: CGPoint, sz: CGFloat, rotation: Double) -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size * sz))
            .foregroundStyle(HomeCharacterDesignTokens.Blossom.accent)
            .rotationEffect(.degrees(rotation))
            .offset(x: size * point.x, y: size * point.y)
    }

    private var fallingLeaf: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size * 0.07))
            .foregroundStyle(HomeCharacterDesignTokens.Blossom.accent.opacity(0.7))
            .rotationEffect(.degrees(45))
            .offset(x: size * 0.32, y: size * 0.10)
    }

    private var dewDrops: some View {
        ZStack {
            Circle()
                .fill(petalColor.opacity(0.6))
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: -size * 0.35, y: size * 0.20)
            Circle()
                .fill(petalColor.opacity(0.4))
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: size * 0.38, y: size * 0.25)
        }
    }
}

// MARK: - Custom Shapes (shared with RippleCharacterView)

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

// MARK: - Preview

#Preview("Blossom - All 8 Moods") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(RippleMood.allCases, id: \.self) { mood in
                VStack(spacing: 8) {
                    BlossomCharacterView(mood: mood, size: 120)
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
