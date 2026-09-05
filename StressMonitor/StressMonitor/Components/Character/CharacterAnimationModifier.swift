import SwiftUI

// MARK: - Character Animation Modifier

/// Applies mood-specific animation to Stress Buddy character.
/// All animation starts ask the app-wide motion helper — under Reduce
/// Motion the character holds a static pose.
struct CharacterAnimationModifier: ViewModifier {
    let mood: RippleMood

    @State private var breathingScale: CGFloat = 1.0
    @State private var fidgetOffset: CGSize = .zero
    @State private var shakeRotation: Double = 0
    @State private var dizzyRotation: Double = 0
    @State private var fidgetTimer: Timer?
    @State private var motionReduced: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(mood == .relaxed ? breathingScale : 1.0)
            .offset(mood == .focused ? fidgetOffset : .zero)
            .rotationEffect(mood == .worried ? .degrees(shakeRotation) : .zero)
            .rotationEffect((mood == .determined || mood == .tired) ? .degrees(dizzyRotation) : .zero)
            .onDisappear {
                fidgetTimer?.invalidate()
                fidgetTimer = nil
            }
            .onMotionDecision { reduced in motionReduced = reduced }
            .startMotionIfAllowed { applyAnimation() }
    }

    // MARK: - Animation Implementations

    private func applyAnimation() {
        switch mood {
        case .relaxed:
            // Breathing animation that previously fired for the legacy `sleeping` mood.
            // `RippleMood.relaxed` is the canonical mapping for very low stress (0–10).
            startBreathing()
        case .serene, .happy, .celebrating:
            // Calm/positive states: no ambient motion.
            break
        case .focused:
            startFidget()
        case .worried:
            startShake()
        case .determined, .tired:
            startDizzy()
        }
    }

    /// Breathing animation: Slow scale 0.95-1.05 over 4s
    private func startBreathing() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            breathingScale = 1.05
        }
    }

    /// Fidget animation: Random offset ±3pt every 2-3s
    private func startFidget() {
        fidgetTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            guard !self.motionReduced else { return }
            let randomX = CGFloat.random(in: -3...3)
            let randomY = CGFloat.random(in: -3...3)

            withAnimation(.easeInOut(duration: 0.5)) {
                self.fidgetOffset = CGSize(width: randomX, height: randomY)
            }

            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.fidgetOffset = .zero
                }
            }
        }
    }

    /// Shake animation: Rotation ±5° over 0.5s
    private func startShake() {
        withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
            shakeRotation = 5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                shakeRotation = -5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                shakeRotation = 0
            }
        }
    }

    /// Dizzy animation: Continuous rotation 360° over 1.5s
    private func startDizzy() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            dizzyRotation = 360
        }
    }
}

extension View {
    /// Apply character animation based on mood
    /// Respects the app-wide motion decision — static pose under Reduce Motion
    /// - Parameter mood: Ripple mood
    /// - Returns: View with animation applied
    func characterAnimation(for mood: RippleMood) -> some View {
        modifier(CharacterAnimationModifier(mood: mood))
    }
}

// MARK: - Accessory Animation Modifier

/// Applies floating animation to character accessories
struct AccessoryAnimationModifier: ViewModifier {
    let index: Int // For staggered animation

    @State private var floatOffset: CGFloat = 0
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: floatOffset)
            .rotationEffect(.degrees(rotation))
            .startMotionIfAllowed { startFloating() }
    }

    private func startFloating() {
        // Stagger animation based on index
        let delay = Double(index) * 0.2

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                floatOffset = -5
                rotation = Double.random(in: -10...10)
            }
        }
    }
}

extension View {
    /// Apply floating animation to accessory
    /// - Parameter index: Index for staggered timing
    func accessoryAnimation(index: Int = 0) -> some View {
        modifier(AccessoryAnimationModifier(index: index))
    }
}
