import UIKit
import CoreHaptics

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private init() {
        setupHapticEngine()
    }

    private func setupHapticEngine() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }

    func stressLevelChanged(to category: StressCategory) {
        guard supportsHaptics else { return }

        switch category {
        case .relaxed:
            success()
        case .mild:
            light()
        case .moderate:
            warning()
        case .high:
            error()
        case .severe:
            error()
        }
    }

    /// Haptic feedback when the Ripple character's mood changes.
    /// Not yet invoked from any mood-transition site; wire it to the point where
    /// `RippleMood.from(stressLevel:)` produces a new mood in a later change.
    /// `.worried` (the canonical mapping for the former `overwhelmed`) fires a heavy impact.
    func rippleMoodChange(to mood: RippleMood) {
        guard supportsHaptics else { return }

        let style: UIImpactFeedbackGenerator.FeedbackStyle = (mood == .worried) ? .heavy : .medium
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func breathingCue() {
        guard supportsHaptics else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }

    func buttonPress() {
        guard supportsHaptics else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func success() {
        guard supportsHaptics else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func warning() {
        guard supportsHaptics else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func error() {
        guard supportsHaptics else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    private func light() {
        guard supportsHaptics else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
