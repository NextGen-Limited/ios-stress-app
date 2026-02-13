import SwiftUI

// MARK: - Character Animation Modifier

/// Applies mood-specific animation to Stress Buddy character
/// All animations respect Reduce Motion accessibility setting
struct CharacterAnimationModifier: ViewModifier {
    let mood: StressBuddyMood
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var breathingScale: CGFloat = 1.0
    @State private var fidgetOffset: CGSize = .zero
    @State private var shakeRotation: Double = 0
    @State private var dizzyRotation: Double = 0
    @State private var fidgetTimer: Timer?

    func body(content: Content) -> some View {
        content
            .scaleEffect(mood == .sleeping ? breathingScale : 1.0)
            .offset(mood == .concerned ? fidgetOffset : .zero)
            .rotationEffect(mood == .worried ? .degrees(shakeRotation) : .zero)
            .rotationEffect(mood == .overwhelmed ? .degrees(dizzyRotation) : .zero)
            .onDisappear {
                fidgetTimer?.invalidate()
                fidgetTimer = nil
            }
            .onAppear {
                if !reduceMotion {
                    applyAnimation()
                }
            }
    }

    // MARK: - Animation Implementations

    private func applyAnimation() {
        switch mood {
        case .sleeping:
            startBreathing()
        case .calm:
            // No animation for calm state
            break
        case .concerned:
            startFidget()
        case .worried:
            startShake()
        case .overwhelmed:
            startDizzy()
        }
    }

    /// Breathing animation: Slow scale 0.95-1.05 over 4s
    private func startBreathing() {
        withAnimation(.breathing(reduceMotion: reduceMotion)) {
            breathingScale = 1.05
        }
    }

    /// Fidget animation: Random offset ±3pt every 2-3s
    private func startFidget() {
        fidgetTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            guard !self.reduceMotion else { return }

            let randomX = CGFloat.random(in: -3...3)
            let randomY = CGFloat.random(in: -3...3)

            withAnimation(.fidget(reduceMotion: false)) {
                self.fidgetOffset = CGSize(width: randomX, height: randomY)
            }

            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.fidget(reduceMotion: false)) {
                    self.fidgetOffset = .zero
                }
            }
        }
    }

    /// Shake animation: Rotation ±5° over 0.5s
    private func startShake() {
        withAnimation(.shake(reduceMotion: reduceMotion)) {
            shakeRotation = 5
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.shake(reduceMotion: reduceMotion)) {
                shakeRotation = -5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.shake(reduceMotion: reduceMotion)) {
                shakeRotation = 0
            }
        }
    }

    /// Dizzy animation: Continuous rotation 360° over 1.5s
    private func startDizzy() {
        withAnimation(.dizzy(reduceMotion: reduceMotion)) {
            dizzyRotation = 360
        }
    }
}

extension View {
    /// Apply character animation based on mood
    /// Respects Reduce Motion accessibility setting
    /// - Parameter mood: Stress Buddy mood
    /// - Returns: View with animation applied
    func characterAnimation(for mood: StressBuddyMood) -> some View {
        modifier(CharacterAnimationModifier(mood: mood))
    }
}

// MARK: - Accessory Animation Modifier

/// Applies floating animation to character accessories
struct AccessoryAnimationModifier: ViewModifier {
    let index: Int // For staggered animation
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var floatOffset: CGFloat = 0
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: floatOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if !reduceMotion {
                    startFloating()
                }
            }
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
    /// - Returns: View with floating animation
    func accessoryAnimation(index: Int = 0) -> some View {
        modifier(AccessoryAnimationModifier(index: index))
    }
}
