import SwiftUI

/// Breathing visualization centered on the Ripple water-droplet character.
///
/// Replaces the former `BreathingCircleView` with a richer design:
/// - Dashed outer ring (260pt) + solid ring (160pt) + rotating active ring
/// - `RippleCharacterView` at center whose mood shifts per breathing phase
/// - Scale animation synced to the breathing cycle (inhale→1.15, hold→1.0, exhale→0.85)
/// - Water sparkles on inhale, water trail particles on exhale
struct RippleBreathingView: View {
    let phase: BreathingSessionViewModel.BreathingPhase
    let scale: Double
    var size: CGFloat = 200

    @State private var ringRotation: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var trailOpacity: Double = 0

    private let ringColor = HomeCharacterDesignTokens.Ripple.primary
    private let deepColor = HomeCharacterDesignTokens.Ripple.deep
    private let lightColor = HomeCharacterDesignTokens.Ripple.light

    var body: some View {
        ZStack {
            // Dashed outer ring (260pt relative to size)
            Circle()
                .stroke(
                    ringColor.opacity(0.25),
                    style: StrokeStyle(lineWidth: 3, dash: [8, 6])
                )
                .frame(width: size * 1.30, height: size * 1.30)

            // Rotating active ring
            Circle()
                .trim(from: 0, to: 0.70)
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.0), ringColor, deepColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: size * 1.30, height: size * 1.30)
                .rotationEffect(.degrees(ringRotation))

            // Solid middle ring (160pt relative to size)
            Circle()
                .stroke(ringColor.opacity(0.35), lineWidth: 2)
                .frame(width: size * 0.80, height: size * 0.80)

            // Soft glow behind character
            Circle()
                .fill(ringColor.opacity(0.12))
                .frame(width: size * 0.90, height: size * 0.90)
                .blur(radius: 12)

            // Ripple character at center, scaled to breathing cycle
            RippleCharacterView(mood: moodForPhase, size: size * 0.68)
                .scaleEffect(scale)
                .shadow(color: ringColor.opacity(0.3), radius: 16)

            // Water sparkles on inhale
            if phase == .inhale {
                sparkleParticles
                    .opacity(sparkleOpacity)
            }

            // Water trail particles on exhale
            if phase == .exhale {
                trailParticles
                    .opacity(trailOpacity)
            }
        }
        .frame(width: size * 1.30, height: size * 1.30)
        .onAppear {
            startRingRotation()
            updatePhaseEffects()
        }
        .onChange(of: phase) {
            updatePhaseEffects()
        }
    }

    // MARK: - Mood Mapping

    private var moodForPhase: RippleMood {
        switch phase {
        case .inhale: return .serene
        case .hold:   return .focused
        case .exhale: return .relaxed
        }
    }

    // MARK: - Ring Rotation

    private func startRingRotation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }

    // MARK: - Phase Effects

    private func updatePhaseEffects() {
        switch phase {
        case .inhale:
            withAnimation(.easeIn(duration: 1.0)) { sparkleOpacity = 1.0 }
            withAnimation(.easeIn(duration: 0.5)) { trailOpacity = 0.0 }
        case .hold:
            withAnimation(.easeInOut(duration: 0.4)) { sparkleOpacity = 0.3 }
            withAnimation(.easeInOut(duration: 0.4)) { trailOpacity = 0.0 }
        case .exhale:
            withAnimation(.easeOut(duration: 1.0)) { sparkleOpacity = 0.0 }
            withAnimation(.easeOut(duration: 1.0)) { trailOpacity = 1.0 }
        }
    }

    // MARK: - Particles

    private var sparkleParticles: some View {
        ZStack {
            breathingSparkle(angle: -45, radius: 0.62)
            breathingSparkle(angle: 30, radius: 0.58)
            breathingSparkle(angle: 135, radius: 0.64)
            breathingSparkle(angle: 200, radius: 0.56)
            breathingSparkle(angle: 290, radius: 0.60)
        }
    }

    private func breathingSparkle(angle: Double, radius: CGFloat) -> some View {
        let radians = angle * .pi / 180
        return Image(systemName: "sparkle")
            .font(.system(size: size * 0.05))
            .foregroundStyle(lightColor.opacity(0.8))
            .offset(
                x: cos(radians) * size * radius,
                y: sin(radians) * size * radius
            )
    }

    private var trailParticles: some View {
        ZStack {
            waterParticle(angle: 210, radius: 0.50)
            waterParticle(angle: 240, radius: 0.55)
            waterParticle(angle: 270, radius: 0.58)
            waterParticle(angle: 300, radius: 0.55)
            waterParticle(angle: 330, radius: 0.50)
        }
    }

    private func waterParticle(angle: Double, radius: CGFloat) -> some View {
        let radians = angle * .pi / 180
        return Circle()
            .fill(lightColor.opacity(0.5))
            .frame(width: size * 0.035, height: size * 0.035)
            .offset(
                x: cos(radians) * size * radius,
                y: sin(radians) * size * radius
            )
    }
}

// MARK: - Preview

#Preview("RippleBreathingView - All Phases") {
    HStack(spacing: 32) {
        VStack(spacing: 8) {
            RippleBreathingView(phase: .inhale, scale: 1.15, size: 200)
            Text("Inhale")
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        VStack(spacing: 8) {
            RippleBreathingView(phase: .hold, scale: 1.0, size: 200)
            Text("Hold")
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        VStack(spacing: 8) {
            RippleBreathingView(phase: .exhale, scale: 0.85, size: 200)
            Text("Exhale")
                .font(.system(size: 14, weight: .medium, design: .rounded))
        }
    }
    .padding(40)
    .background(HomeCharacterDesignTokens.homeBackground)
}
