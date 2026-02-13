import SwiftUI

// MARK: - Gradient Extensions
extension LinearGradient {
    /// Calm wellness gradient for backgrounds
    /// Combines calm blue and health green for soothing effect
    static let calmWellness = LinearGradient(
        colors: [
            Color.Wellness.calmBlue.opacity(0.1),
            Color.Wellness.healthGreen.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Stress spectrum gradient that maps to stress levels
    /// - Parameter category: The stress category
    /// - Returns: Gradient representing the stress level
    static func stressSpectrum(for category: StressCategory) -> LinearGradient {
        let baseColor = Color.stressColor(for: category)
        return LinearGradient(
            colors: [
                baseColor.opacity(0.6),
                baseColor.opacity(0.3),
                baseColor.opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Background tint gradient for cards based on stress level
    /// - Parameter category: The stress category
    /// - Returns: Subtle gradient for card backgrounds
    static func stressBackgroundTint(for category: StressCategory) -> LinearGradient {
        let baseColor = Color.stressColor(for: category)
        return LinearGradient(
            colors: [
                baseColor.opacity(0.08),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Mindfulness gradient (gentle purple to calm blue)
    static let mindfulness = LinearGradient(
        colors: [
            Color.Wellness.gentlePurple.opacity(0.15),
            Color.Wellness.calmBlue.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Relaxation gradient (health green to transparent)
    static let relaxation = LinearGradient(
        colors: [
            Color.Wellness.healthGreen.opacity(0.15),
            Color.Wellness.healthGreen.opacity(0.05),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Gradient View Modifiers
extension View {
    /// Apply wellness background gradient
    func wellnessBackground() -> some View {
        self.background(LinearGradient.calmWellness)
    }

    /// Apply stress-level specific background gradient
    /// - Parameter category: The stress category
    func stressBackground(for category: StressCategory) -> some View {
        self.background(LinearGradient.stressBackgroundTint(for: category))
    }

    /// Apply card background with stress spectrum gradient overlay
    /// - Parameters:
    ///   - category: The stress category
    ///   - baseColor: Base color for the card (default: surface)
    func stressCard(for category: StressCategory, baseColor: Color = Color.Wellness.surface) -> some View {
        self
            .background {
                ZStack {
                    baseColor
                    LinearGradient.stressBackgroundTint(for: category)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
