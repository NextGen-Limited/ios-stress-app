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
        }
    }

    func stressBuddyMoodChange(to mood: StressBuddyMood) {
        guard supportsHaptics else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
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
